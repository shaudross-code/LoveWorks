import Foundation

// Assuming we want to dynamically retrieve and update the iOS theme, we should patch Theme.swift directly
let path = "./iLoveWorks/Theme.swift"
var contents = try! String(contentsOfFile: path)
contents = contents.replacingOccurrences(of: "struct Theme {", with: """
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var effectiveTheme: String = "default"
    
    private init() {
        Task { await fetchTheme() }
    }
    
    func fetchTheme() async {
        do {
            let url = URL(string: "https://labor-admin-hub.emergent.host/api/theme")!
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let effective = json["effective"] as? String {
                DispatchQueue.main.async {
                    self.effectiveTheme = effective
                }
            }
        } catch {
            print("Failed fetching theme: \\(error)")
        }
    }
}

struct Theme {
""")
contents = contents.replacingOccurrences(of: "static let primary = Color(hex: \"#FACC15\") // Gold remains as primary accent", with: """
    static var primary: Color {
        ThemeManager.shared.effectiveTheme == "halloween" ? Color(hex: "#F97316") : Color(hex: "#FACC15")
    }
""")
contents = contents.replacingOccurrences(of: "static let lovePink = Color(hex: \"#F472B6\") // Pink-rose for rebrand", with: """
    static var lovePink: Color {
        ThemeManager.shared.effectiveTheme == "halloween" ? Color(hex: "#F97316") : Color(hex: "#F472B6") // Pink-rose for rebrand
    }
""")
contents = contents.replacingOccurrences(of: "static let loveGradient = LinearGradient(\n        gradient: Gradient(colors: [Color(hex: \"#F472B6\"), Color(hex: \"#E11D48\")]),\n        startPoint: .topLeading,\n        endPoint: .bottomTrailing\n    )", with: """
    static var loveGradient: LinearGradient {
        if ThemeManager.shared.effectiveTheme == "halloween" {
            return LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#F97316"), Color(hex: "#9333EA")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#F472B6"), Color(hex: "#E11D48")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
""")
try! contents.write(toFile: path, atomically: true, encoding: .utf8)
print("Updated Theme.swift")
