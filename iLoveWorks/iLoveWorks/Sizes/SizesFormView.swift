import SwiftUI

struct SizesFormView: View {
    @StateObject var state: SizesFormState
    let isAdmin: Bool
    let onSubmit: ([String: AnyValue], String, MeasurementUnit) -> Void
    
    @State private var expandedSections: Set<String> = []
    @State private var shouldNotify = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Form Sections
                ForEach(SizesConstants.SECTIONS) { section in
                    if !SizeHelper.sectionFields(section, state.fit).isEmpty {
                        sectionCard(section)
                    }
                }
                
                if isAdmin {
                    Toggle("Notify worker of updates", isOn: $shouldNotify)
                        .tint(Theme.lovePink)
                        .padding()

                
                        .background(Theme.surface)
                        .cornerRadius(12)
                }
                
                // Footer Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onSubmit(state.getRawDict(), state.fit, state.units)
                    }) {
                        Text("Save Sizes")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding()

                
                            .background(Theme.loveGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button("Clear form") {
                        state.values.removeAll()
                        state.canon.removeAll()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                }
                .padding(.top)
            }
            .padding()

                
        }
        .background(Theme.background.ignoresSafeArea())
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Size Details")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Fit Segments
                Picker("Body Fit", selection: Binding(
                    get: { state.fit },
                    set: { state.changeFit(to: $0) }
                )) {
                    ForEach(FitGroup.allCases) { group in
                        Text(group.label).tag(group.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                HStack(spacing: 16) {
                    // Units
                    Picker("Units", selection: Binding(
                        get: { state.units },
                        set: { state.changeUnits(to: $0) }
                    )) {
                        Text("Imperial").tag(MeasurementUnit.imperial)
                        Text("Metric").tag(MeasurementUnit.metric)
                    }
                    .pickerStyle(.segmented)
                    
                    // Shoes
                    Picker("Shoes", selection: Binding(
                        get: { state.shoeScale },
                        set: { state.changeShoeScale(to: $0) }
                    )) {
                        ForEach(ShoeScale.allCases) { scale in
                            Text(scale.rawValue).tag(scale)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    private func sectionCard(_ section: SizeSection) -> some View {
        let isExpanded = expandedSections.contains(section.key)
        let stats = state.getFilledCount(for: section)
        
        return VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    if isExpanded { expandedSections.remove(section.key) }
                    else { expandedSections.insert(section.key) }
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(stats.filled) of \(stats.total) filled")
                            .font(.system(size: 12))
                            .foregroundColor(stats.filled == stats.total ? Theme.success : Theme.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(Theme.textMuted)
                }
                .padding()

                
                .background(Theme.surface)
            }
            
            if isExpanded {
                Divider().background(Theme.border)
                VStack(spacing: 16) {
                    Text(section.blurb)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(SizeHelper.sectionFields(section, state.fit)) { field in
                        fieldView(field)
                    }
                }
                .padding()

                
                .background(Theme.surface)
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
    }
    
    @ViewBuilder
    private func fieldView(_ field: SizeField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(field.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textMain)
                
                Spacer()
                
                if field.type == .length {
                    Text(SizeHelper.lengthUnit(state.units))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                } else if field.type == .weight {
                    Text(SizeHelper.weightUnit(state.units))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                } else if field.type == .shoe {
                    Text(state.shoeScale.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }
            }
            
            if field.type == .chips, let options = field.options {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(options, id: \.self) { opt in
                            let isSelected = state.values[field.key] == opt
                            Button(action: {
                                state.values[field.key] = isSelected ? "" : opt
                            }) {
                                Text(opt)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Theme.primary.opacity(0.15) : Color.clear)
                                    .foregroundColor(isSelected ? Theme.primary : Theme.textMain)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Theme.primary : Theme.border, lineWidth: 1))
                            }
                        }
                    }
                }
            } else if field.type == .textarea {
                TextEditor(text: Binding(
                    get: { state.values[field.key] ?? "" },
                    set: { state.values[field.key] = $0 }
                ))
                .frame(height: 100)
                .padding(8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            } else {
                TextField(field.label, text: Binding(
                    get: { state.values[field.key] ?? "" },
                    set: {
                        if SizeHelper.isNum(field.type) {
                            state.setNumeric(k: field.key, raw: $0)
                        } else {
                            state.values[field.key] = $0
                        }
                    }
                ))
                
                .padding()


                
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
            }
        }
    }
}
