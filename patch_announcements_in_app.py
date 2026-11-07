import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

# Add a function to AdminViewModel to push an announcement
new_func = """    func pushAnnouncement(title: String, body: String, tag: String) async throws {
        let payload = ["title": title, "body": body, "tag": tag]
        let _: EmptyResponse = try await APIClient.shared.send("/announcements", method: "POST", json: payload)
        await refresh()
    }"""
text = text.replace("func updateCompanyConfig", new_func + "\n\n    func updateCompanyConfig")

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)
print("Added pushAnnouncement to AdminViewModel")
