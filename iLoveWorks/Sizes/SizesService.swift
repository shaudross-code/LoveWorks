import Foundation

struct SizeField: Identifiable {
    var id: String { key + (fits ?? []).joined() }
    let key: String
    let label: String
    let type: FieldType
    let fits: [String]?
    let options: [String]?
    var placeholder: String? = nil

    enum FieldType {
        case length
        case height
        case weight
        case shoe
        case chips
        case text
        case textarea
    }
}

enum FitGroup: String, CaseIterable, Identifiable {
    case mens
    case womens
    case unspecified
    var id: String { rawValue }

    var label: String {
        switch self {
        case .mens: return "Men's"
        case .womens: return "Women's"
        case .unspecified: return "Prefer not to say"
        }
    }
}

enum MeasurementUnit: String, Identifiable {
    case metric
    case imperial
    var id: String { rawValue }
}

enum ShoeScale: String, CaseIterable, Identifiable {
    case US, EU, UK
    var id: String { rawValue }
}

struct SizeSection: Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let blurb: String
    let fields: [SizeField]
}

enum SizesConstants {
    static let LETTER = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"]
    static let LETTER6 = ["XS", "S", "M", "L", "XL", "XXL"]
    static let SML = ["S", "M", "L", "XL"]
    static let BANDS = ["28", "30", "32", "34", "36", "38", "40", "42", "44", "46"]
    static let CUPS = ["AA", "A", "B", "C", "D", "DD", "DDD", "F", "G", "H"]
    static let DRESS = ["00", "0", "2", "4", "6", "8", "10", "12", "14", "16", "18", "20"]

    static func L(_ k: String, _ label: String) -> SizeField {
        SizeField(key: k, label: label, type: .length, fits: nil, options: nil)
    }
    static func C(_ k: String, _ label: String, _ options: [String], _ fits: [String]? = nil) -> SizeField {
        SizeField(key: k, label: label, type: .chips, fits: fits, options: options)
    }

    static let SECTIONS = [
        SizeSection(key: "body", title: "Body", blurb: "Measured snug, not tight.", fields: [
            SizeField(key: "height", label: "Height", type: .height, fits: nil, options: nil),
            SizeField(key: "weight", label: "Weight", type: .weight, fits: nil, options: nil),
            L("neck", "Neck"), L("shoulder", "Shoulder width"), L("chest", "Chest / bust"),
            L("waist", "Waist"), L("hips", "Hips"), L("sleeve", "Sleeve length"),
            L("inseam", "Inseam"), L("head", "Head circumference"), L("hand", "Hand circumference")
        ]),
        SizeSection(key: "footwear", title: "Footwear", blurb: "Boots, shoes and width.", fields: [
            SizeField(key: "shoe_us", label: "Shoe size", type: .shoe, fits: nil, options: nil),
            C("shoe_width", "Width", ["Narrow", "Regular", "Wide", "Extra wide"]),
            SizeField(key: "boot_notes", label: "Boot preferences", type: .text, fits: nil, options: nil, placeholder: "Steel toe, high-top, slip-resistant…")
        ]),
        SizeSection(key: "casual", title: "Casual fits", blurb: "Everyday clothes off the clock.", fields: [
            C("casual_top", "Casual top / tee", LETTER), C("hoodie", "Hoodie / sweater", LETTER),
            L("jeans_waist", "Jeans waist"), L("jeans_inseam", "Jeans inseam"), C("shorts", "Shorts", LETTER),
            C("dress", "Dress size", DRESS, ["womens"]),
            C("casual_fit", "Preferred fit", ["Slim", "Regular", "Relaxed", "Oversized"])
        ]),
        SizeSection(key: "workout", title: "Workout fits", blurb: "Gym, training and team activewear.", fields: [
            C("workout_top", "Workout top", LETTER), C("workout_shorts", "Workout shorts", LETTER),
            C("joggers", "Joggers / sweatpants", LETTER), C("workout_leggings", "Leggings / tights", LETTER6),
            C("compression", "Compression / base layer", LETTER6),
            C("workout_fit", "Preferred fit", ["Fitted", "Regular", "Loose"])
        ]),
        SizeSection(key: "workwear", title: "Workwear", blurb: "Shirts, jackets, pants and gear.", fields: [
            C("top", "Top / T-shirt", LETTER), C("jacket", "Jacket / outerwear", LETTER),
            L("pants_waist", "Pants waist"), L("pants_inseam", "Pants inseam"), C("pants_letter", "Pants (letter size)", LETTER),
            C("gloves", "Gloves", LETTER6), C("hat", "Hat", LETTER6), C("hivis", "Hi-vis vest", LETTER)
        ]),
        SizeSection(key: "underclothes", title: "Underclothes", blurb: "Only what fits your chosen fit.", fields: [
            C("underwear_style", "Underwear style", ["Briefs", "Boxers", "Boxer briefs", "Trunks"], ["mens"]),
            C("underwear_size", "Underwear size", LETTER, ["mens"]),
            C("undershirt", "Undershirt", LETTER, ["mens"]),
            C("socks", "Sock size", SML, ["mens"]),
            C("bra_band", "Bra band", BANDS, ["womens", "unspecified"]),
            C("bra_cup", "Bra cup", CUPS, ["womens", "unspecified"]),
            C("sports_bra", "Sports bra", LETTER6, ["womens", "unspecified"]),
            C("underwear_style", "Underwear style", ["Briefs", "Bikini", "Boyshort", "Thong"], ["womens"]),
            C("underwear_size", "Underwear size", LETTER, ["womens"]),
            C("leggings", "Leggings / base layer", LETTER6, ["womens"]),
            C("socks", "Sock / hosiery size", SML, ["womens"]),
            C("underwear_size", "Underwear size", LETTER, ["unspecified"]),
            C("base_layer", "Base layer", LETTER6, ["unspecified"]),
            C("socks", "Sock size", SML, ["unspecified"])
        ]),
        SizeSection(key: "notes", title: "Fit notes", blurb: "Anything that doesn't fit a box.", fields: [
            SizeField(key: "fit_notes", label: "Notes", type: .textarea, fits: nil, options: nil, placeholder: "Long torso, prefers loose fit, fabric sensitivities…")
        ])
    ]
}

enum SizeHelper {
    static let ALL_FIELDS = SizesConstants.SECTIONS.flatMap { $0.fields }

    static func effectiveFit(_ fit: String?) -> String {
        let f = fit ?? ""
        return f.isEmpty ? "unspecified" : f
    }

    static func applicable(_ field: SizeField, _ fit: String?) -> Bool {
        guard let fits = field.fits else { return true }
        return fits.contains(effectiveFit(fit))
    }

    static func sectionFields(_ section: SizeSection, _ fit: String?) -> [SizeField] {
        section.fields.filter { applicable($0, fit) }
    }

    /// Same as the web: up to 1 decimal, no trailing ".0".
    static func fmtNum(_ n: Double?) -> String {
        guard let n = n, n.isFinite else { return "" }
        let r = (n * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(format: "%.1f", r)
    }

    static func lengthUnit(_ unit: MeasurementUnit) -> String { unit == .metric ? "cm" : "in" }
    static func weightUnit(_ unit: MeasurementUnit) -> String { unit == .metric ? "kg" : "lb" }

    static func isLength(_ t: SizeField.FieldType) -> Bool { t == .length || t == .height }

    static func toDisplay(type: SizeField.FieldType, cm: Double, unit: MeasurementUnit) -> Double {
        if isLength(type) { return unit == .metric ? cm : cm / 2.54 }
        if type == .weight { return unit == .metric ? cm : cm * 2.20462 }
        return cm
    }

    static func toCanonical(type: SizeField.FieldType, v: Double, unit: MeasurementUnit) -> Double {
        if isLength(type) { return unit == .metric ? v : v * 2.54 }
        if type == .weight { return unit == .metric ? v : v / 2.20462 }
        return v
    }

    static func shoeOffsets(_ fit: String?) -> (uk: Double, eu: Double) {
        effectiveFit(fit) == "womens" ? (uk: -2, eu: 31) : (uk: -1, eu: 33)
    }

    static func shoeFromUS(_ us: Double, _ fit: String?, _ scale: ShoeScale) -> Double {
        let o = shoeOffsets(fit)
        switch scale {
        case .US: return us
        case .UK: return us + o.uk
        case .EU: return ((us + o.eu) * 2).rounded() / 2
        }
    }

    static func shoeToUS(_ v: Double, _ scale: ShoeScale, _ fit: String?) -> Double {
        let o = shoeOffsets(fit)
        if scale == .UK { return v - o.uk }
        if scale == .EU { return v - o.eu }
        return v
    }

    static func typeOf(_ k: String) -> SizeField.FieldType {
        ALL_FIELDS.first(where: { $0.key == k })?.type ?? .text
    }

    static func isNum(_ t: SizeField.FieldType) -> Bool {
        t == .length || t == .weight || t == .shoe || t == .height
    }

    /// Imperial height split into feet + half-inches.
    static func ftIn(_ totalIn: Double) -> (ft: Int, inch: Double) {
        var ft = Int(floor(totalIn / 12))
        var inch = ((totalIn - Double(ft) * 12) * 2).rounded() / 2
        if inch >= 12 { ft += 1; inch = 0 }
        return (ft, inch)
    }

    static func isStale(_ iso: String?) -> Bool {
        guard let d = APIDate.parse(iso) else { return false }
        return Date().timeIntervalSince(d) > 365 * 86_400
    }
}

/// Form state: `values` are display strings, `canon` holds exact canonical numbers (cm / kg / US shoe).
struct SizesForm: Equatable {
    var fit: String?
    var values: [String: String] = [:]
    var canon: [String: Double] = [:]
    var shoeScale: ShoeScale

    init(doc: SizesDoc?, units: MeasurementUnit) {
        fit = (doc?.fit ?? "").isEmpty ? nil : doc?.fit
        shoeScale = units == .metric ? .EU : .US
        for (k, v) in doc?.values ?? [:] {
            let t = SizeHelper.typeOf(k)
            if SizeHelper.isNum(t), let n = v.doubleValue {
                canon[k] = n
                values[k] = display(t, n, units)
            } else {
                values[k] = v.stringValue
            }
        }
        if units == .imperial { syncHeightParts() }
    }

    private func display(_ t: SizeField.FieldType, _ n: Double, _ units: MeasurementUnit) -> String {
        t == .shoe ? SizeHelper.fmtNum(SizeHelper.shoeFromUS(n, fit, shoeScale)) : SizeHelper.fmtNum(SizeHelper.toDisplay(type: t, cm: n, unit: units))
    }

    private mutating func syncHeightParts() {
        if let h = canon["height"] {
            let p = SizeHelper.ftIn(h / 2.54)
            values["height_ft"] = String(p.ft)
            values["height_in"] = SizeHelper.fmtNum(p.inch)
        } else {
            values["height_ft"] = ""
            values["height_in"] = ""
        }
    }

    func value(_ k: String) -> String { values[k] ?? "" }

    mutating func setText(_ k: String, _ v: String) { values[k] = v }

    mutating func setNumeric(_ k: String, _ raw: String, units: MeasurementUnit) {
        values[k] = raw
        let t = SizeHelper.typeOf(k)
        if let n = Double(raw.replacingOccurrences(of: ",", with: ".")), n.isFinite {
            canon[k] = t == .shoe ? SizeHelper.shoeToUS(n, shoeScale, fit) : SizeHelper.toCanonical(type: t, v: n, unit: units)
        } else {
            canon.removeValue(forKey: k)
        }
    }

    mutating func setHeightImperial(ft: String, inch: String) {
        values["height_ft"] = ft
        values["height_in"] = inch
        let f = Double(ft), i = Double(inch.replacingOccurrences(of: ",", with: "."))
        if f == nil && i == nil {
            canon.removeValue(forKey: "height")
            values["height"] = ""
        } else {
            let total = (f ?? 0) * 12 + (i ?? 0)
            canon["height"] = total * 2.54
            values["height"] = SizeHelper.fmtNum(total)
        }
    }

    mutating func convert(from: MeasurementUnit, to: MeasurementUnit) {
        guard from != to else { return }
        for (k, c) in canon {
            let t = SizeHelper.typeOf(k)
            if SizeHelper.isLength(t) || t == .weight { values[k] = SizeHelper.fmtNum(SizeHelper.toDisplay(type: t, cm: c, unit: to)) }
        }
        if to == .imperial { syncHeightParts() }
    }

    mutating func changeShoeScale(_ scale: ShoeScale) {
        shoeScale = scale
        if let c = canon["shoe_us"] { values["shoe_us"] = SizeHelper.fmtNum(SizeHelper.shoeFromUS(c, fit, scale)) }
    }

    mutating func changeFit(_ newFit: String) {
        if let n = Double(values["shoe_us"] ?? "") { canon["shoe_us"] = SizeHelper.shoeToUS(n, shoeScale, newFit) }
        fit = newFit
    }

    mutating func clear() {
        values = [:]
        canon = [:]
    }

    /// Values to send: canonical numbers for numeric fields, strings otherwise; only fields that apply to the fit.
    func payload() -> [String: AnyValue] {
        var out: [String: AnyValue] = [:]
        for (k, raw) in values where !raw.isEmpty {
            guard let field = SizeHelper.ALL_FIELDS.first(where: { $0.key == k && SizeHelper.applicable($0, fit) }) else { continue }
            if SizeHelper.isNum(field.type) {
                if let c = canon[k] { out[k] = .double(c) }
            } else {
                out[k] = .string(raw)
            }
        }
        return out
    }

    func completion(_ section: SizeSection) -> (filled: Int, total: Int) {
        let fields = SizeHelper.sectionFields(section, fit)
        return (fields.filter { !value($0.key).isEmpty }.count, fields.count)
    }
}
