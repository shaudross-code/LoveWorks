import SwiftUI
import Combine

/// Observable wrapper around the pure `SizesForm` used by My Sizes and the admin worker-sizes sheet.
final class SizesFormModel: ObservableObject {
    @Published var form: SizesForm
    @Published private(set) var units: MeasurementUnit
    @Published var doc: SizesDoc?
    private var original: [String: AnyValue] = [:]
    private var originalFit: String?

    init(doc: SizesDoc? = nil) {
        let u = MeasurementUnit(rawValue: doc?.units ?? "imperial") ?? .imperial
        units = u
        form = SizesForm(doc: doc, units: u)
        load(doc)
    }

    func load(_ doc: SizesDoc?) {
        self.doc = doc
        let u = MeasurementUnit(rawValue: doc?.units ?? "imperial") ?? .imperial
        units = u
        form = SizesForm(doc: doc, units: u)
        original = form.payload()
        originalFit = form.fit
    }

    var hasChanges: Bool { form.payload() != original || form.fit != originalFit }

    func setUnits(_ u: MeasurementUnit) {
        guard u != units else { return }
        form.convert(from: units, to: u)
        form.changeShoeScale(u == .metric ? .EU : .US)
        units = u
    }
}
