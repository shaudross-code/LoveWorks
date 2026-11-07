import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add Profile to MoreView
more_view_pattern = r"(NavigationLink\(destination: AdminAnnouncementsView\(viewModel: viewModel\)\) \{\n.*?Label\(\"Announcements\", systemImage: \"megaphone.fill\"\)\n.*?\})"

replacement = r"""\1
                        NavigationLink(destination: AdminProfileView()) {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }"""

new_text = re.sub(more_view_pattern, replacement, text)

# Add AdminProfileView at the end
profile_view = """

struct AdminProfileView: View {
    @EnvironmentObject var session: SessionManager
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "PROFILE", title: "Your account.")
                    HStack {
                        Circle().fill(Theme.secondary).frame(width: 80, height: 80)
                            .overlay(Text(String(session.currentUser?.name.prefix(1) ?? "A")).font(.title).bold().foregroundStyle(.white))
                        VStack(alignment: .leading) {
                            Text("Signed in as").font(.caption).foregroundStyle(Theme.textMuted)
                            Text(session.currentUser?.email ?? "").font(.title3).bold().foregroundStyle(Theme.textMain)
                            Text(session.currentUser?.role.rawValue.capitalized ?? "Admin").font(.caption).padding(6).background(Theme.primary.opacity(0.2)).foregroundStyle(Theme.primary).cornerRadius(8)
                        }
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                    
                    Button(action: { session.logout() }) {
                        Text("Logout").bold().frame(maxWidth: .infinity).padding().background(Theme.surface).foregroundStyle(Theme.danger).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Profile")
    }
}
"""

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(new_text + profile_view)

