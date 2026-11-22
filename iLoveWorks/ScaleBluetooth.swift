//
//  ScaleBluetooth.swift
//  iLoveWorks
//
//  Reads a weigh-in straight from an Etekcity (VeSync) smart scale over Bluetooth.
//  Bluetooth permission is only requested when the worker taps "Weigh in".
//

#if os(iOS) && canImport(CoreBluetooth)
import Foundation
import Combine
import CoreBluetooth

final class ScaleBluetooth: NSObject, ObservableObject {
    static let shared = ScaleBluetooth()

    enum Phase: Equatable {
        case idle, searching, connecting, weighing, got, unsupported, bluetoothOff, denied, timedOut
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var reading: ScaleReading?
    @Published private(set) var foundName: String?
    @Published private(set) var savedName = UserDefaults.standard.string(forKey: Keys.name)

    private enum Keys {
        static let id = "ilw.scale.id"
        static let name = "ilw.scale.name"
    }

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var writeChar: CBCharacteristic?
    private var model: ScaleModel?
    private var candidateID: UUID?
    private var vendor: UInt8 = 0x15
    private var sentUnit = false
    private var sentTime = false
    private var sawSettling = false
    private var active = false
    private var timeout: Task<Void, Never>?

    private var savedID: UUID? { UserDefaults.standard.string(forKey: Keys.id).flatMap(UUID.init) }
    private var usesPounds: Bool { Locale.current.measurementSystem == .us }

    func start() {
        resetSession()
        active = true
        if let central {
            handle(central.state)
        } else {
            central = CBCentralManager(delegate: self, queue: .main)  // shows the Bluetooth prompt the first time
        }
    }

    func cancel() {
        stop()
        phase = .idle
    }

    func forget() {
        UserDefaults.standard.removeObject(forKey: Keys.id)
        UserDefaults.standard.removeObject(forKey: Keys.name)
        savedName = nil
    }

    private func resetSession() {
        reading = nil
        foundName = nil
        model = nil
        candidateID = nil
        vendor = 0x15
        sentUnit = false
        sentTime = false
        sawSettling = false
    }

    private func handle(_ state: CBManagerState) {
        guard active else { return }
        switch state {
        case .poweredOn: scan()
        case .poweredOff: phase = .bluetoothOff
        case .unauthorized: phase = .denied
        case .unsupported: phase = .failed("This device doesn't have Bluetooth.")
        default: break
        }
    }

    private func scan() {
        guard let central, central.state == .poweredOn, phase != .searching else { return }
        phase = .searching
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(90))
            guard let self, !Task.isCancelled, self.reading == nil, self.active else { return }
            self.stop()
            self.phase = .timedOut
        }
    }

    private func stop() {
        active = false
        timeout?.cancel()
        central?.stopScan()
        if let p = peripheral { central?.cancelPeripheralConnection(p) }
        peripheral = nil
        writeChar = nil
    }

    private func finish(_ r: ScaleReading) {
        guard reading == nil else { return }
        reading = r
        phase = .got
        if let id = candidateID {
            UserDefaults.standard.set(id.uuidString, forKey: Keys.id)
            UserDefaults.standard.set(foundName, forKey: Keys.name)
            savedName = foundName
        }
        if model == .esf24, let p = peripheral, let c = writeChar {
            write(ScaleProtocol.esf24End(vendor: vendor), to: c, on: p)
        }
        timeout?.cancel()
        central?.stopScan()
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.stop()
        }
    }

    private func write(_ data: Data, to c: CBCharacteristic, on p: CBPeripheral) {
        p.writeValue(data, for: c, type: c.properties.contains(.write) ? .withResponse : .withoutResponse)
    }

    private func handleFrame(_ bytes: [UInt8]) {
        switch model {
        case .esf551:
            if let r = ScaleProtocol.parseESF551(bytes) { finish(r) }
        case .esf24:
            guard let p = peripheral, let c = writeChar else { return }
            switch ScaleProtocol.classifyESF24(bytes, vendor: vendor) {
            case .unitRequest(let v):
                vendor = v
                if !sentUnit { sentUnit = true; write(ScaleProtocol.esf24Unit(pounds: usesPounds, vendor: v), to: c, on: p) }
            case .timeRequest:
                if !sentTime { sentTime = true; write(ScaleProtocol.esf24Time(vendor: vendor), to: c, on: p) }
            case .final(let r): finish(r)
            case .settling, .other: break
            }
        default: break
        }
    }
}

extension ScaleBluetooth: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handle(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard active, reading == nil, self.peripheral == nil else { return }
        if let saved = savedID, peripheral.identifier != saved { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        let mfr = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        guard let m = ScaleProtocol.detect(name: name, manufacturer: mfr) else { return }
        foundName = name ?? "Etekcity \(m.rawValue)"
        candidateID = peripheral.identifier
        model = m
        switch m {
        case .locked:
            stop()
            phase = .unsupported
        case .fit8s:
            phase = .weighing
            guard let payload = ScaleProtocol.split(mfr)?.payload else { return }
            if let r = ScaleProtocol.parseFIT8S(payload) {
                if sawSettling { finish(r) }  // skip the last weigh-in the scale may still be advertising
            } else {
                sawSettling = true
            }
        case .esf551, .esf24:
            self.peripheral = peripheral
            peripheral.delegate = self
            central.stopScan()
            phase = .connecting
            central.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        phase = .weighing
        peripheral.discoverServices([CBUUID(string: ScaleProtocol.serviceID)])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        stop()
        phase = .failed("Couldn't connect to the scale. Close the VeSync app and try again.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard reading == nil, active else { return }
        stop()
        phase = .failed("The scale turned off before a reading came through. Step on it again and tap Try again.")
    }
}

extension ScaleBluetooth: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: ScaleProtocol.serviceID) }) else {
            stop()
            phase = .unsupported
            return
        }
        peripheral.discoverCharacteristics([CBUUID(string: ScaleProtocol.notifyID), CBUUID(string: ScaleProtocol.writeID)], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics ?? [] {
            if c.uuid == CBUUID(string: ScaleProtocol.notifyID) { peripheral.setNotifyValue(true, for: c) }
            if c.uuid == CBUUID(string: ScaleProtocol.writeID) { writeChar = c }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        handleFrame([UInt8](data))
    }
}
#endif
