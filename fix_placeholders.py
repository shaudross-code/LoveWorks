import re

admin_views = """
struct AdminGoalsView: View {
    @ObservedObject var viewModel: AdminViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "GOALS", title: "Target practice.")
                    ForEach(viewModel.goals) { goal in
                        GoalCard(goal: goal)
                    }
                }
                .padding()
            }
        }
    }
}

struct AdminTripsView: View {
    @ObservedObject var viewModel: AdminViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "ADVENTURE", title: "Trips")
                    ForEach(viewModel.trips) { trip in
                        GoalCard(goal: trip)
                    }
                }
                .padding()
            }
        }
    }
}

struct AdminPayrollView: View {
    @ObservedObject var viewModel: AdminViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "PAYROLL", title: "Who earned what.")
                    let totalEarn = viewModel.payroll.reduce(0) { $0 + $1.tasksEarnings }
                    let totalHours = viewModel.payroll.reduce(0) { $0 + $1.totalHours }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("TOTAL DUE").font(.caption).foregroundStyle(Theme.textMuted)
                            Text("$\(String(format: "%.2f", totalEarn))").font(.title).bold().foregroundStyle(Theme.primary)
                        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                        
                        VStack(alignment: .leading) {
                            Text("LOGGED HOURS").font(.caption).foregroundStyle(Theme.textMuted)
                            Text("\(String(format: "%.1f", totalHours))h").font(.title).bold().foregroundStyle(Theme.textMain)
                        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                    }

                    ForEach(viewModel.payroll) { row in
                        HStack {
                            Circle().fill(Theme.secondary).frame(width: 44, height: 44)
                                .overlay(Text(String(row.worker.name.prefix(1))).bold().foregroundStyle(.white))
                            VStack(alignment: .leading) {
                                Text(row.worker.name).bold().foregroundStyle(Theme.textMain)
                                Text("\(row.tasksCompleted) tasks • \(String(format: "%.1f", row.totalHours))h").font(.caption).foregroundStyle(Theme.textMuted)
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", row.tasksEarnings))").bold().foregroundStyle(Theme.primary)
                        }
                        .padding().background(Theme.surface).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
    }
}

struct AdminAnnouncementsView: View {
    @ObservedObject var viewModel: AdminViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "ANNOUNCEMENTS", title: "Broadcasts.")
                    ForEach(viewModel.announcements) { ann in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ann.title).font(.headline).foregroundStyle(Theme.textMain)
                            Text(ann.body).font(.subheadline).foregroundStyle(Theme.textMuted)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
    }
}

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
                            Text(session.currentUser?.role ?? "Admin").font(.caption).padding(6).background(Theme.primary.opacity(0.2)).foregroundStyle(Theme.primary).cornerRadius(8)
                        }
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                    
                    ThemeSettingsView() // Exists natively!
                    
                    Button(action: { Task { await session.logout() }}) {
                        Text("Logout").bold().frame(maxWidth: .infinity).padding().background(Theme.surface).foregroundStyle(Theme.danger).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
    }
}
"""

worker_views = """
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
                                Text(entry.task?.title ?? "Activity").bold().foregroundStyle(Theme.textMain)
                                Text(entry.date ?? "").font(.caption).foregroundStyle(Theme.textMuted)
                            }
                            Spacer()
                            Text("\(String(format: "%.1f", entry.hours))h").bold().foregroundStyle(Theme.textMain)
                        }
                        .padding().background(Theme.surface).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
    }
}

struct WorkerAnnouncementsView: View {
    @ObservedObject var viewModel: WorkerViewModel
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "ANNOUNCEMENTS", title: "Broadcasts.")
                    ForEach(viewModel.announcements) { ann in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ann.title).font(.headline).foregroundStyle(Theme.textMain)
                            Text(ann.body).font(.subheadline).foregroundStyle(Theme.textMuted)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
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
                            Text(session.currentUser?.role ?? "Worker").font(.caption).padding(6).background(Theme.primary.opacity(0.2)).foregroundStyle(Theme.primary).cornerRadius(8)
                        }
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(Theme.surface).cornerRadius(16)

                    Button(action: { Task { await session.logout() }}) {
                        Text("Logout").bold().frame(maxWidth: .infinity).padding().background(Theme.surface).foregroundStyle(Theme.danger).cornerRadius(16)
                    }
                }
                .padding()
            }
        }
    }
}
"""

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    aview = f.read()

# Replace placeholders usage in AdminDashboardView switcher
# case .goals: AdminGoalsPlaceholder() -> case .goals: AdminGoalsView(viewModel: viewModel)
# case .trips: AdminTripsPlaceholder() -> case .trips: AdminTripsView(viewModel: viewModel)
# case .payroll: AdminPayrollPlaceholder() -> case .payroll: AdminPayrollView(viewModel: viewModel)
# case .announcements: AdminAnnouncementsPlaceholder() -> case .announcements: AdminAnnouncementsView(viewModel: viewModel)
# case .profile: AdminProfilePlaceholder() -> case .profile: AdminProfileView()
aview = re.sub(r'case \.goals:\s*AdminGoalsPlaceholder\(\)', 'case .goals:\\n                        AdminGoalsView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.trips:\s*AdminTripsPlaceholder\(\)', 'case .trips:\\n                        AdminTripsView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.payroll:\s*AdminPayrollPlaceholder\(\)', 'case .payroll:\\n                        AdminPayrollView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.announcements:\s*AdminAnnouncementsPlaceholder\(\)', 'case .announcements:\\n                        AdminAnnouncementsView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.profile:\s*AdminProfilePlaceholder\(\)', 'case .profile:\\n                        AdminProfileView()', aview)

# Strip out the placehoder structs and slap on our newly fully integrated custom views!
aview = re.sub(r'// Temporary Placeholders.*?\n(struct Admin.*?Placeholder.*?\n)+', admin_views, aview, flags=re.DOTALL)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(aview)


with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    wview = f.read()

wview = re.sub(r'case \.history:\s*WorkerHistoryPlaceholder\(\)', 'case .history:\\n                        WorkerHistoryView(viewModel: viewModel)', wview)
wview = re.sub(r'case \.announcements:\s*WorkerAnnouncementsPlaceholder\(\)', 'case .announcements:\\n                        WorkerAnnouncementsView(viewModel: viewModel)', wview)
wview = re.sub(r'case \.profile:\s*WorkerProfilePlaceholder\(\)', 'case .profile:\\n                        WorkerProfileView()', wview)

wview = re.sub(r'// Temporary Placeholders.*?\n(struct Worker.*?Placeholder.*?\n)+', worker_views, wview, flags=re.DOTALL)

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(wview)

print("Placeholders completely eliminated and fully substituted with actual views.")
