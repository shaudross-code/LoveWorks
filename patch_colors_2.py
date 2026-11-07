import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# Apply Settings tab explicitly to WorkerDashboardView if missing to match Admin settings
settings_enum_regex = r"case sizes = \"My Sizes\"\n    case profile = \"Profile\""
settings_enum_new = "case sizes = \"My Sizes\"\n    case settings = \"Settings\"\n    case profile = \"Profile\""
if settings_enum_regex in text:
    text = text.replace(settings_enum_regex, settings_enum_new)

icons_regex = r"case \.sizes: return \"ruler\.fill\"\n        case \.profile: return \"person\.crop\.circle\.fill\""
icons_new = "case .sizes: return \"ruler.fill\"\n        case .settings: return \"gearshape.fill\"\n        case .profile: return \"person.crop.circle.fill\""
if icons_regex in text:
    text = text.replace(icons_regex, icons_new)

switch_regex = r"case \.sizes:\n                        MySizesView\(\)\n                    case \.profile:"
switch_new = "case .sizes:\n                        MySizesView()\n                    case .settings:\n                        WorkerSettingsView()\n                    case .profile:"
if switch_regex in text:
    text = text.replace(switch_regex, switch_new)

settings_view = """
struct WorkerSettingsView: View {
    @AppStorage("useMetric") private var useMetric = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PREFERENCES")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Theme.lovePink)
                            .tracking(1.5)
                        Text("Settings.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Regional Options")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Global Measurement System")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Theme.textMain)
                                    Text(useMetric ? "Metric" : "Imperial / U.S.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.lovePink)
                                }
                                Spacer()
                                Toggle("", isOn: $useMetric)
                                    .tint(Theme.lovePink)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                        }
                        .background(Theme.surface)
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}
"""

if "struct WorkerSettingsView: View" not in text:
    if "struct WorkerProfileView: View {" in text:
        text = text.replace("struct WorkerProfileView: View {", settings_view + "\nstruct WorkerProfileView: View {")
    else:
        text += settings_view

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)

print("Injected Worker Settings View")
