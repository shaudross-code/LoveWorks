import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# Replace TabView block with the custom horizontal tabs
tabview_pattern = re.compile(r"struct WorkerDashboardView: View \{.*?(?=\nstruct WorkerDashboardMainView: View)", re.DOTALL)

replacement = """
enum WorkerTab: String, CaseIterable, Identifiable {
    case workday = "Workday"
    case history = "History"
    case trips = "Trips"
    case essentials = "Essentials"
    case awards = "Awards"
    case announcements = "What's new"
    case sizes = "My Sizes"
    case profile = "Profile"

    var id: String { self.rawValue }
    var label: String { self.rawValue }

    var icon: String {
        switch self {
        case .workday: return "clock.fill"
        case .history: return "clock.arrow.circlepath"
        case .trips: return "airplane"
        case .essentials: return "briefcase.fill"
        case .awards: return "trophy.fill"
        case .announcements: return "megaphone.fill"
        case .sizes: return "ruler.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab: WorkerTab = .workday

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Custom Navigation Bar (Mobile Header)
                VStack(spacing: 0) {
                    // Header Actions
                    HStack {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.loveGradient)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Theme.lovePink.opacity(0.3), radius: 4, x: 0, y: 2)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("iLoveWorks")
                                    .font(.custom("Outfit-Bold", size: 16))
                                    .foregroundStyle(Theme.primary)
                                Text("Workspace")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundStyle(Theme.textMuted)
                            }
                            
                            HolidayBadge(compact: true)
                        }
                        
                        Spacer()
                        
                        // Notifications & Logout
                        HStack(spacing: 16) {
                            Button(action: {
                                sessionManager.logout()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 12))
                                    Text("Logout")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.secondary.opacity(0.7))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    Divider().background(Theme.border.opacity(0.5))

                    // Horizontal Scrolling Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { scrollProxy in
                            HStack(spacing: 8) {
                                ForEach(WorkerTab.allCases) { tab in
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = tab
                                            scrollProxy.scrollTo(tab.id, anchor: .center)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: tab.icon)
                                                .font(.system(size: 14))
                                            Text(tab.label)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedTab == tab ? Theme.lovePink : Color.clear)
                                        .foregroundStyle(selectedTab == tab ? .white : Theme.textMuted)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(selectedTab == tab ? Theme.lovePink : Theme.primary.opacity(0.2), lineWidth: 1))
                                    }
                                    .id(tab.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }
                    Divider().background(Theme.border.opacity(0.5))
                }
                .background(Color.black.opacity(0.85)) // matches blur layout

                // Main Content
                Group {
                    switch selectedTab {
                    case .workday:
                        WorkerDashboardMainView(viewModel: viewModel)
                    case .history:
                        WorkerHistoryView(viewModel: viewModel)
                    case .tasks, .goals, .payroll: // some tabs are workers specific
                        Text("Not available for Worker") // To avoid compilation error if missing cases. Wait, WorkerTab instances: workday, history, trips, essentials, awards, announcements, sizes, profile.
                    case .trips:
                        WorkerTripsView(viewModel: viewModel)
                    case .essentials:
                        WorkerEssentialsView(viewModel: viewModel)
                    case .awards:
                        WorkerAwardsView(viewModel: viewModel)
                    case .announcements:
                        WorkerAnnouncementsView(viewModel: viewModel)
                    case .sizes:
                        MySizesView()
                    case .profile:
                        WorkerProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pushOpened)) { _ in viewModel.loadData() }
    }
}
"""
# Need to remove the dummy case in my script text:
replacement = replacement.replace("case .tasks, .goals, .payroll: // some tabs are workers specific\\n                        Text(\\\"Not available for Worker\\\") // To avoid compilation error if missing cases. Wait, WorkerTab instances: workday, history, trips, essentials, awards, announcements, sizes, profile.", "")

new_text = tabview_pattern.sub(replacement, text)

# Now, we should remove WorkerMoreView because it's no longer used.
worker_more_pattern = re.compile(r"struct WorkerMoreView: View \{.*?(?=\nstruct WorkerHistoryView: View)", re.DOTALL)
new_text = worker_more_pattern.sub("", new_text)

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(new_text)

