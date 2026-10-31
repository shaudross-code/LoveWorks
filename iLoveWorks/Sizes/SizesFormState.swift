import SwiftUI
import Combine

class SizesFormState: ObservableObject {
    @Published var fit: String
    @Published var units: MeasurementUnit
    @Published var shoeScale: ShoeScale
    @Published var values: [String: String]
    var canon: [String: Double]
    var originalValues: [String: AnyValue]
    
    init(data: SizesData?) {
        let theFit = SizeHelper.effectiveFit(data?.fit)
        let theUnits = MeasurementUnit(rawValue: data?.units ?? "imperial") ?? .imperial
        let initialShoeScale: ShoeScale = theUnits == .metric ? .EU : .US
        
        self.fit = theFit
        self.units = theUnits
        self.shoeScale = initialShoeScale
        self.values = [:]
        self.canon = [:]
        self.originalValues = data?.values ?? [:]
        
        // build from original canon values
        for (k, v) in originalValues {
            let t = SizeHelper.typeOf(k)
            if SizeHelper.isNum(t) {
                if let dbl = v.doubleValue {
                    canon[k] = dbl
                    values[k] = displayStr(t: t, canonV: dbl, u: theUnits, s: initialShoeScale, f: theFit)
                }
            } else {
                values[k] = v.stringValue
            }
        }
    }
    
    private func displayStr(t: SizeField.FieldType, canonV: Double, u: MeasurementUnit, s: ShoeScale, f: String) -> String {
        if t == .shoe {
            let conv = SizeHelper.shoeFromUS(canonV, f)
            let val = s == .US ? conv.us : (s == .EU ? conv.eu : conv.uk)
            return SizeHelper.fmtNum(val)
        }
        return SizeHelper.fmtNum(SizeHelper.toDisplay(type: t, cm: canonV, unit: u))
    }
    
    func setNumeric(k: String, raw: String) {
        values[k] = raw
        let t = SizeHelper.typeOf(k)
        if let n = Double(raw) {
            canon[k] = t == .shoe ? SizeHelper.shoeToUS(n, shoeScale, fit) : SizeHelper.toCanonical(type: t, v: n, unit: units)
        } else {
            canon.removeValue(forKey: k)
        }
    }
    
    func changeUnits(to newUnits: MeasurementUnit) {
        if newUnits == units { return }
        self.units = newUnits
        for (k, c) in canon {
            let t = SizeHelper.typeOf(k)
            if t == .length || t == .weight {
                values[k] = SizeHelper.fmtNum(SizeHelper.toDisplay(type: t, cm: c, unit: newUnits))
            }
        }
    }
    
    func changeShoeScale(to newScale: ShoeScale) {
        if newScale == shoeScale { return }
        self.shoeScale = newScale
        if let c = canon["shoe_us"] {
            let conv = SizeHelper.shoeFromUS(c, fit)
            let val = newScale == .US ? conv.us : (newScale == .EU ? conv.eu : conv.uk)
            values["shoe_us"] = SizeHelper.fmtNum(val)
        }
    }
    
    func changeFit(to newFit: String) {
        if let n = Double(values["shoe_us"] ?? "") {
            canon["shoe_us"] = SizeHelper.shoeToUS(n, shoeScale, newFit)
        }
        self.fit = newFit
    }
    
    func getRawDict() -> [String: AnyValue] {
        var out: [String: AnyValue] = [:]
        for (k, raw) in values {
            if raw.isEmpty { continue }
            guard let field = SizeHelper.ALL_FIELDS.first(where: { $0.key == k && SizeHelper.applicable($0, fit) }) else { continue }
            
            if SizeHelper.isNum(field.type) {
                if let c = canon[k] {
                    out[k] = .double(c)
                }
            } else {
                out[k] = .string(raw)
            }
        }
        return out
    }
    
    func getFilledCount(for section: SizeSection) -> (filled: Int, total: Int) {
        let fields = SizeHelper.sectionFields(section, fit)
        let filled = fields.filter { !(values[$0.key] ?? "").isEmpty }.count
        return (filled, fields.count)
    }
}
