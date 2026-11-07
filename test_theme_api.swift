import Foundation

struct ThemeResponse: Codable {
    let mode: String
    let effective: String
    let endsOn: String?
    // etc... 
}

func testThemeAPI() async {
    // Just a quick check of what the endpoint returns
    let url = URL(string: "https://labor-admin-hub.emergent.host/api/theme")!
    let (data, _) = try! await URLSession.shared.data(from: url)
    print(String(data: data, encoding: .utf8)!)
}
Task { await testThemeAPI(); exit(0) }
RunLoop.main.run()
