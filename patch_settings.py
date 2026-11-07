import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add AdminSettingsView
settings_enum_regex = r"case sizes = \"My Sizes\"\n    case profile = \"Profile\""
settings_enum_new = "case sizes = \"My Sizes\"\n    case settings = \"Settings\"\n    case profile = \"Profile\""
if settings_enum_regex in text:
    text = text.replace(settings_enum_regex, settings_enum_new)

icons_regex = r"case \.sizes: return \"ruler\.fill\"\n        case \.profile: return \"person\.crop\.circle\.fill\""
icons_new = "case .sizes: return \"ruler.fill\"\n        case .settings: return \"gearshape.fill\"\n        case .profile: return \"person.crop.circle.fill\""
if icons_regex in text:
    text = text.replace(icons_regex, icons_new)

switch_regex = r"case \.sizes:\n                        MySizesView\(\)\n                    case \.profile:"
switch_new = "case .sizes:\n                        MySizesView()\n                    case .settings:\n                        AdminSettingsView()\n                    case .profile:"
if switch_regex in text:
    text = text.replace(switch_regex, switch_new)

settings_view = """
struct AdminSettingsView: View {
    @AppStorage("useMetric") private var useMetric = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "COMPANY OPTIONS", title: "Settings.")
                    
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
        .navigationBarHidden(true)
    }
}
"""

if "struct AdminSettingsView: View" not in text:
    old = "struct AdminProfileView: View {"
    text = text.replace(old, settings_view + "\n" + old)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

print("Injected Settings View")
