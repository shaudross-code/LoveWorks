import Foundation

struct SizeField: Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let type: FieldType
    let fits: [String]?
    let options: [String]?
    
    enum FieldType {
        case length
        case weight
        case shoe
        case chips
        case text
        case textarea
    }
}

enum FitGroup: String, CaseIterable, Identifiable {
    case mens = "mens"
    case womens = "womens"
    case unspecified = "unspecified"
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
    case metric = "metric"
    case imperial = "imperial"
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

struct SizesData: Codable {
    let id: String
    let user_id: String
    var fit: String
    var units: String
    var values: [String: AnyValue]
    let updated_at: String
    let created_at: String
    let updated_by: UpdatedBy
    
    struct UpdatedBy: Codable {
        let id: String
        let name: String
        let role: String
    }
}

enum AnyValue: Codable, Equatable {
    case string(String)
    case double(Double)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Double.self) {
            self = .double(x)
        } else if let x = try? container.decode(String.self) {
            self = .string(x)
        } else if let x = try? container.decode(Int.self) {
            self = .int(x)
        } else {
            throw DecodingError.typeMismatch(AnyValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for AnyValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x): try container.encode(x)
        case .double(let x): try container.encode(x)
        case .int(let x): try container.encode(x)
        }
    }
    
    var doubleValue: Double? {
        if case .double(let x) = self { return x }
        if case .int(let x) = self { return Double(x) }
        return nil
    }
    
    var stringValue: String {
        switch self {
        case .string(let x): return x
        case .double(let x): return "\(x)"
        case .int(let x): return "\(x)"
        }
    }
}

struct SizesConstants {
    static let LETTER = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"]
    static let LETTER6 = ["XS", "S", "M", "L", "XL", "XXL"]
    static let SML = ["S", "M", "L", "XL"]
    static let BANDS = ["28", "30", "32", "34", "36", "38", "40", "42", "44", "46"]
    static let CUPS = ["AA", "A", "B", "C", "D", "DD", "DDD", "F", "G", "H"]
    
    static func L(_ k: String, _ label: String) -> SizeField {
        SizeField(key: k, label: label, type: .length, fits: nil, options: nil)
    }
    static func C(_ k: String, _ label: String, _ options: [String], _ fits: [String]? = nil) -> SizeField {
        SizeField(key: k, label: label, type: .chips, fits: fits, options: options)
    }
    
    static let SECTIONS = [
        SizeSection(key: "body", title: "Body", blurb: "Measured snug, not tight.", fields: [
            L("height", "Height"),
            SizeField(key: "weight", label: "Weight", type: .weight, fits: nil, options: nil),
            L("neck", "Neck"), L("shoulder", "Shoulder width"), L("chest", "Chest / bust"),
            L("waist", "Waist"), L("hips", "Hips"), L("sleeve", "Sleeve length"),
            L("inseam", "Inseam"), L("head", "Head circumference"), L("hand", "Hand circumference")
        ]),
        SizeSection(key: "footwear", title: "Footwear", blurb: "Boots, shoes and width.", fields: [
            SizeField(key: "shoe_us", label: "Shoe size", type: .shoe, fits: nil, options: nil),
            C("shoe_width", "Width", ["Narrow", "Regular", "Wide", "Extra wide"]),
            SizeField(key: "boot_notes", label: "Boot preferences", type: .text, fits: nil, options: nil)
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
            SizeField(key: "fit_notes", label: "Notes", type: .textarea, fits: nil, options: nil)
        ])
    ]
}

class SizeHelper {
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
        return section.fields.filter { applicable($0, fit) }
    }
    
    static func fmtNum(_ n: Double?) -> String {
        guard let n = n else { return "" }
        let isInt = floor(n) == n
        return isInt ? String(Int(n)) : String(format: "%.1f", n)
    }
    
    static func lengthUnit(_ unit: MeasurementUnit) -> String { unit == .metric ? "cm" : "in" }
    static func weightUnit(_ unit: MeasurementUnit) -> String { unit == .metric ? "kg" : "lb" }
    
    static func toDisplay(type: SizeField.FieldType, cm: Double, unit: MeasurementUnit) -> Double {
        if type == .length { return unit == .metric ? cm : cm / 2.54 }
        if type == .weight { return unit == .metric ? cm : cm * 2.20462 }
        return cm
    }
    
    static func toCanonical(type: SizeField.FieldType, v: Double, unit: MeasurementUnit) -> Double {
        if type == .length { return unit == .metric ? v : v * 2.54 }
        if type == .weight { return unit == .metric ? v : v / 2.20462 }
        return v
    }
    
    static func shoeOffsets(_ fit: String?) -> (uk: Double, eu: Double) {
        effectiveFit(fit) == "womens" ? (uk: -2, eu: 31) : (uk: -1, eu: 33)
    }
    
    static func shoeFromUS(_ us: Double, _ fit: String?) -> (us: Double, uk: Double, eu: Double) {
        let o = shoeOffsets(fit)
        return (us, us + o.uk, round((us + o.eu) * 2) / 2)
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
        t == .length || t == .weight || t == .shoe
    }
}
