import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# Add More to TabView
tab_pattern = r"(MySizesView\(\)\n\s*\.tabItem \{ Label\(\"My Sizes\", systemImage: \"ruler\.fill\"\) \}\n)"

replacement = r"""\1
            WorkerMoreView(viewModel: viewModel)
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
"""
new_text = re.sub(tab_pattern, replacement, text)


# Implement the actual views
worker_views = """

struct WorkerMoreView: View {
    @ObservedObject var viewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    Section {
                        NavigationLink(destination: WorkerHistoryView(viewModel: viewModel)) {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        NavigationLink(destination: WorkerAnnouncementsView(viewModel: viewModel)) {
                            Label("Announcements", systemImage: "megaphone.fill")
                        }
                        NavigationLink(destination: WorkerProfileView()) {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }
                    } header: {
                        Text("Options")
                    }
                    .listRowBackground(Theme.surface)
                    
                    Section {
                        Button(action: { sessionManager.logout() }) {
                            Label("Log Out", systemImage: "power")
                                .foregroundStyle(Theme.danger)
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("More")
            }
        }
    }
}


struct WorkerHistoryView: View {
    @ObservedObject var viewModel: WorkerViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "HISTORY", title: "Time log.")
                    ForEach(viewModel.allEntries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.activity ?? "Activity").bold().foregroundStyle(Theme.textMain)
                                Text(entry.clockIn).font(.caption).foregroundStyle(Theme.textMuted)
                            }
                            Spacer()
                            let hours = (entry.durationSeconds ?? 0) / 3600.0
                            Text("\\(String(format: "%.1f", hours))h").bold().foregroundStyle(Theme.textMain)
                        }
                        .padding().background(Theme.surface).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("History")
    }
}


struct WorkerAnnouncementsView: View {
    @ObservedObject var viewModel: WorkerViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "WHAT'S NEW", title: "Announcements.")
                    ForEach(viewModel.announcements) { ann in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(ann.title).font(.headline).foregroundStyle(Theme.textMain)
                                Spacer()
                                Text((ann.tag ?? "").uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.lovePink.opacity(0.15))
                                    .foregroundStyle(Theme.lovePink)
                                    .cornerRadius(4)
                            }
                            Text(ann.body).font(.subheadline).foregroundStyle(Theme.textMuted)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Announcements")
    }
}


struct WorkerProfileView: View {
    @EnvironmentObject var session: SessionManager
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "PROFILE", title: "Your account.")
                    HStack {
                        Circle().fill(Theme.secondary).frame(width: 80, height: 80)
                            .overlay(Text(String(session.currentUser?.name.prefix(1) ?? "W")).font(.title).bold().foregroundStyle(.white))
                        VStack(alignment: .leading) {
                            Text("Signed in as").font(.caption).foregroundStyle(Theme.textMuted)
                            Text(session.currentUser?.email ?? "").font(.title3).bold().foregroundStyle(Theme.textMain)
                            Text(session.currentUser?.role.rawValue.capitalized ?? "Worker").font(.caption).padding(6).background(Theme.primary.opacity(0.2)).foregroundStyle(Theme.primary).cornerRadius(8)
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

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(new_text + worker_views)

