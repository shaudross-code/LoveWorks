import SwiftUI

/// Fit picker, units toggle and the collapsible size sections (Body → Fit notes).
struct SizesFormView: View {
    @ObservedObject var model: SizesFormModel
    var highlight: Set<String> = []

    @State private var expanded: Set<String> = ["body"]
    @State private var guideKey: String?

    var body: some View {
        VStack(spacing: 16) {
            fitCard
            ForEach(SizesConstants.SECTIONS) { section in
                if !SizeHelper.sectionFields(section, model.form.fit).isEmpty {
                    sectionCard(section)
                }
            }
        }
        .sheet(item: Binding(get: { guideKey.map(GuideKey.init) }, set: { guideKey = $0?.id })) { k in
            MeasureGuideView(startKey: k.id)
        }
        .onAppear {
            for s in SizesConstants.SECTIONS where SizeHelper.sectionFields(s, model.form.fit).contains(where: { highlight.contains($0.key) }) {
                expanded.insert(s.key)
            }
        }
    }

    private struct GuideKey: Identifiable { let id: String }

    // MARK: Fit + units

    private var fitCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            FieldLabel(text: "Fit")
            FlowLayout(spacing: 8) {
                ForEach(FitGroup.allCases) { g in
                    let on = model.form.fit == g.rawValue
                    Button { model.form.changeFit(g.rawValue) } label: {
                        Text(g.label)
                            .font(.system(size: 14, weight: on ? .semibold : .regular))
                            .padding(.horizontal, 16)
                            .frame(minHeight: 40)
                            .background(on ? Theme.lovePink : Color.clear)
                            .foregroundStyle(on ? .white : Theme.textMain)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(on ? Theme.lovePink : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            if model.form.fit == nil {
                Text("Pick a fit to show the right clothing and underclothes sizes.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
            }

            HStack(spacing: 0) {
                unitButton(.imperial, "in · lb · US")
                unitButton(.metric, "cm · kg · EU")
            }
            .padding(4)
            .background(Color.zinc.opacity(0.6))
            .clipShape(Capsule())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(highlight.contains("fit") ? Theme.lovePink : .clear, lineWidth: 2))
    }

    private func unitButton(_ u: MeasurementUnit, _ label: String) -> some View {
        let on = model.units == u
        return Button { model.setUnits(u) } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(on ? Theme.primary : Color.clear)
                .foregroundStyle(on ? .black : Theme.textMuted)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Sections

    private func sectionCard(_ section: SizeSection) -> some View {
        let isOpen = expanded.contains(section.key)
        let stats = model.form.completion(section)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isOpen { expanded.remove(section.key) } else { expanded.insert(section.key) }
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                        Text(section.blurb)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    Text("\(stats.filled) of \(stats.total) filled")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(stats.filled == stats.total && stats.total > 0 ? Theme.success.opacity(0.12) : Color.zinc.opacity(0.6))
                        .foregroundStyle(stats.filled == stats.total && stats.total > 0 ? Theme.success : Theme.textMuted)
                        .clipShape(Capsule())
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(alignment: .leading, spacing: 18) {
                    if section.key == "body" {
                        Button { guideKey = "height" } label: {
                            Label("How to measure — tap any “How” for a picture", systemImage: "book.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .frame(minHeight: 36)
                                .foregroundStyle(Theme.primaryHover)
                                .overlay(Capsule().stroke(Theme.primary.opacity(0.35), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(SizeHelper.sectionFields(section, model.form.fit)) { field in
                        fieldView(field)
                            .padding(highlight.contains(field.key) ? 8 : 0)
                            .background(highlight.contains(field.key) ? Theme.lovePink.opacity(0.06) : .clear)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(highlight.contains(field.key) ? Theme.lovePink.opacity(0.7) : .clear, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: Fields

    @ViewBuilder
    private func fieldView(_ field: SizeField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                FieldLabel(text: field.label)
                if MeasureGuide.keys.contains(field.key) {
                    Button { guideKey = field.key } label: {
                        Label("How", systemImage: "questionmark.circle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("How to measure \(field.label.lowercased())")
                }
            }

            switch field.type {
            case .chips:
                FlowLayout(spacing: 8) {
                    ForEach(field.options ?? [], id: \.self) { opt in
                        let on = model.form.value(field.key) == opt
                        Button { model.form.setText(field.key, on ? "" : opt) } label: {
                            Text(opt)
                                .font(.system(size: 14, weight: on ? .semibold : .regular))
                                .padding(.horizontal, 14)
                                .frame(minHeight: 38)
                                .background(on ? Theme.primary : Color.clear)
                                .foregroundStyle(on ? .black : Theme.textMain)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(on ? Theme.primary : Theme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            case .height where model.units == .imperial:
                HStack(spacing: 10) {
                    unitInput(text: Binding(get: { model.form.value("height_ft") }, set: { model.form.setHeightImperial(ft: $0, inch: model.form.value("height_in")) }), unit: "ft", integer: true)
                    unitInput(text: Binding(get: { model.form.value("height_in") }, set: { model.form.setHeightImperial(ft: model.form.value("height_ft"), inch: $0) }), unit: "in")
                }
                if let cm = model.form.canon["height"] {
                    Text("\(SizeHelper.fmtNum(cm)) cm").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                }
            case .length, .height, .weight:
                unitInput(text: numeric(field.key), unit: field.type == .weight ? SizeHelper.weightUnit(model.units) : SizeHelper.lengthUnit(model.units))
            case .shoe:
                shoeField
            case .text:
                TextField(field.placeholder ?? field.label, text: Binding(get: { model.form.value(field.key) }, set: { model.form.setText(field.key, String($0.prefix(60))) }))
                    .inputBox()
            case .textarea:
                TextField(field.placeholder ?? field.label, text: Binding(get: { model.form.value(field.key) }, set: { model.form.setText(field.key, String($0.prefix(1000))) }), axis: .vertical)
                    .lineLimit(3...8)
                    .inputBox()
            }
        }
    }

    private var shoeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                TextField("—", text: numeric("shoe_us"))
                    .decimalKeyboard()
                    .frame(width: 90)
                    .inputBox()
                HStack(spacing: 0) {
                    ForEach(ShoeScale.allCases) { s in
                        let on = model.form.shoeScale == s
                        Button { model.form.changeShoeScale(s) } label: {
                            Text(s.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 44, height: 36)
                                .background(on ? Theme.primary : Color.clear)
                                .foregroundStyle(on ? .black : Theme.textMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color.zinc.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if let us = model.form.canon["shoe_us"] {
                let others = ShoeScale.allCases.filter { $0 != model.form.shoeScale }
                Text(others.map { "\($0.rawValue) \(SizeHelper.fmtNum(SizeHelper.shoeFromUS(us, model.form.fit, $0)))" }.joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }

    private func numeric(_ key: String) -> Binding<String> {
        Binding(get: { model.form.value(key) }, set: { model.form.setNumeric(key, $0, units: model.units) })
    }

    private func unitInput(text: Binding<String>, unit: String, integer: Bool = false) -> some View {
        HStack {
            if integer {
                TextField("—", text: text).numberKeyboard()
            } else {
                TextField("—", text: text).decimalKeyboard()
            }
            Text(unit).font(.system(size: 12)).foregroundStyle(Theme.textMuted)
        }
        .inputBox()
    }
}

private extension View {
    func inputBox() -> some View {
        self.font(.system(size: 16))
            .foregroundStyle(Theme.textMain)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.zinc.opacity(0.5))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.zinc, lineWidth: 1))
    }
}
