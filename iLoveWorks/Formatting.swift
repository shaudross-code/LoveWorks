//
//  Formatting.swift
//  iLoveWorks
//

import Foundation

enum APIDate {
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let dayOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Parses the backend's ISO strings: "…T18:14:00.174231+00:00", "…T00:00:00+00:00" or "2026-06-05".
    static func parse(_ raw: String?) -> Date? {
        guard var s = raw, !s.isEmpty else { return nil }
        if s.count == 10 { return dayOnly.date(from: s) }
        if s.hasSuffix("Z") == false, s.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) == nil {
            s += "Z"
        }
        // ISO8601DateFormatter only understands up to 3 fractional digits
        if let r = s.range(of: #"\.\d+"#, options: .regularExpression) {
            let frac = s[r].prefix(4)
            s.replaceSubrange(r, with: frac)
        }
        return withFraction.date(from: s) ?? plain.date(from: s)
    }

    static func short(_ raw: String?) -> String {
        guard let d = parse(raw) else { return "—" }
        return d.formatted(date: .abbreviated, time: .shortened)
    }

    static func day(_ raw: String?) -> String {
        guard let d = parse(raw) else { return "—" }
        return d.formatted(.dateTime.month(.abbreviated).day())
    }
}

enum Fmt {
    static func money(_ v: Double) -> String {
        v.rounded() == v ? "$\(Int(v))" : String(format: "$%.2f", v)
    }

    static func hm(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return "\(s / 3600)h \((s % 3600) / 60)m"
    }

    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}
