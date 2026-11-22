//
//  ScaleProtocol.swift
//  iLoveWorks
//
//  Decodes Etekcity (VeSync) smart-scale Bluetooth data. Byte layouts follow the
//  open-source etekcity_esf551_ble project. Supported: ESF-551, ESF-24/17/18, FIT-8S.
//

import Foundation

enum ScaleModel: String {
    case esf551 = "ESF-551"
    case esf24 = "ESF-24"
    case fit8s = "FIT-8S"
    case locked = "Etekcity (encrypted)"

    var usesConnection: Bool { self == .esf551 || self == .esf24 }
}

struct ScaleReading: Equatable {
    let kg: Double
    let impedance: Int?
    let at: Date
}

enum ScaleProtocol {
    static let serviceID = "FFF0"
    static let notifyID = "FFF1"
    static let writeID = "FFF2"

    private static let etekcityCompany: UInt16 = 1744
    private static let qnCompany: UInt16 = 0xFFFF
    private static let epoch2000: TimeInterval = 946_656_000

    /// Manufacturer data from iOS starts with the 2-byte little-endian company ID.
    static func split(_ data: Data?) -> (company: UInt16, payload: [UInt8])? {
        guard let data, data.count >= 2 else { return nil }
        let b = [UInt8](data)
        return (UInt16(b[0]) | UInt16(b[1]) << 8, Array(b.dropFirst(2)))
    }

    static func detect(name: String?, manufacturer: Data?) -> ScaleModel? {
        if let (company, p) = split(manufacturer) {
            if company == etekcityCompany, p.count >= 9 {
                switch Int(p[7]) << 8 | Int(p[8]) {
                case 1, 2, 12: return .esf551
                case 49321: return .fit8s
                case 3, 5, 127, 134, 136: return .locked
                default: if p[0] & 0x0F == 2 { return .locked }  // newer encrypted generation
                }
            }
            if company == qnCompany, p.count >= 2, [294, 946, 211, 671].contains(Int(p[0]) << 8 | Int(p[1])) {
                return .esf24
            }
        }
        guard let n = name?.lowercased() else { return nil }
        if n.hasPrefix("qn-scale") { return .esf24 }
        if n.contains("etekcity") && n.contains("scale") { return .esf551 }
        return nil
    }

    // MARK: ESF-551 (notifications on FFF1, nothing to write)

    static func isESF551Frame(_ d: [UInt8]) -> Bool {
        d.count == 22 && d[0] == 0xA5 && d[1] == 0x02 && d[3] == 0x10 && d[4] == 0x00
            && d[6] == 0x01 && d[7] == 0x61 && d[8] == 0xA1 && d[9] == 0x00
    }

    static func parseESF551(_ d: [UInt8]) -> ScaleReading? {
        guard isESF551Frame(d), d[19] == 1 else { return nil }
        let grams = Int(d[10]) | Int(d[11]) << 8 | Int(d[12]) << 16
        let imp = Int(d[13]) | Int(d[14]) << 8
        guard grams > 0 else { return nil }
        return ScaleReading(kg: Double(grams) / 1000, impedance: d[20] == 1 && imp > 0 ? imp : nil, at: Date())
    }

    // MARK: FIT-8S (weight is in the advertisement, no connection)

    static func parseFIT8S(_ p: [UInt8]) -> ScaleReading? {
        guard p.count == 20, p[15] == 0x01 else { return nil }
        let grams = Int(p[10]) | Int(p[11]) << 8 | Int(p[12]) << 16
        let imp = Int(p[13]) | Int(p[14]) << 8
        guard grams > 0 else { return nil }
        return ScaleReading(kg: Double(grams) / 1000, impedance: imp > 0 ? imp : nil, at: Date())
    }

    // MARK: ESF-24 / ESF-17 / ESF-18 (short handshake on FFF2)

    enum ESF24Frame {
        case unitRequest(vendor: UInt8)
        case timeRequest
        case settling
        case final(ScaleReading)
        case other
    }

    static func classifyESF24(_ d: [UInt8], vendor: UInt8) -> ESF24Frame {
        if d.count >= 10, d[0] == 0x12 { return .unitRequest(vendor: d[2]) }
        if d.count >= 11, d[0] == 0x14, d[1] == 0x0B, d[2] == vendor { return .timeRequest }
        if d.count >= 11, d[0] == 0x10, d[1] == 0x0B, d[2] == vendor {
            guard d[5] == 0x01 else { return .settling }
            let centi = Int(d[3]) << 8 | Int(d[4])
            let imp = Int(d[6]) << 8 | Int(d[7])
            return .final(ScaleReading(kg: Double(centi) / 100, impedance: imp > 0 ? imp : nil, at: Date()))
        }
        return .other
    }

    private static func withChecksum(_ bytes: [UInt8]) -> Data {
        Data(bytes + [UInt8(bytes.reduce(0) { ($0 + Int($1)) } & 0xFF)])
    }

    /// Tells the scale which unit to show (kg or lb).
    static func esf24Unit(pounds: Bool, vendor: UInt8) -> Data {
        withChecksum([0x13, 0x09, vendor, pounds ? 0x02 : 0x01, 0x10, 0x28, 0x37, 0x00])
    }

    /// Answers the scale's clock request; it starts measuring after this.
    static func esf24Time(vendor: UInt8, now: Date = Date()) -> Data {
        let t = UInt32(max(0, now.timeIntervalSince1970 - epoch2000))
        return withChecksum([0x20, 0x08, vendor, UInt8(t & 0xFF), UInt8(t >> 8 & 0xFF), UInt8(t >> 16 & 0xFF), UInt8(t >> 24 & 0xFF)])
    }

    /// Stops the scale repeating its final frame.
    static func esf24End(vendor: UInt8) -> Data {
        withChecksum([0x1F, 0x05, vendor, 0x10])
    }
}
