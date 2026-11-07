import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

tabview_pattern = re.compile(r"struct AdminDashboardView: View \{.*?(?=\nstruct AdminDashboardMainView: View)", re.DOTALL)

replacement = """
enum AdminTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case workers = "Workers"
    case tasks = "Tasks"
    case goals = "Goals"
    case trips = "Trips"
    case essentials = "Essentials"
    case payroll = "Payroll"
    case announcements = "Announcements"
    case sizes = "My Sizes"
    case profile = "Profile"

    var id: String { self.rawValue }
    var label: String { self.rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .workers: return "person.2.fill"
        case .tasks: return "checklist"
        case .goals: return "target"
        case .trips: return "airplane"
        case .essentials: return "cart.fill"
        case .payroll: return "dollarsign.circle.fill"
        case .announcements: return "megaphone.fill"
        case .sizes: return "ruler.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedTab: AdminTab = .overview
    
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
                                Text("Admin Console")
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
                                ForEach(AdminTab.allCases) { tab in
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
                    case .overview:
                        AdminDashboardMainView(viewModel: viewModel)
                    case .workers:
                        AdminWorkersView(viewModel: viewModel)
                    case .tasks:
                        AdminTasksView(viewModel: viewModel)
                    case .goals:
                        AdminGoalsView(viewModel: viewModel)
                    case .trips:
                        AdminTripsView(viewModel: viewModel)
                    case .essentials:
                        AdminEssentialsView(viewModel: viewModel)
                    case .payroll:
                        AdminPayrollView(viewModel: viewModel)
                    case .announcements:
                        AdminAnnouncementsView(viewModel: viewModel)
                    case .sizes:
                        MySizesView()
                    case .profile:
                        AdminProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
"""
new_text = tabview_pattern.sub(replacement, text)

# Now, we remove AdminMoreView because it's no longer used.
admin_more_pattern = re.compile(r"struct AdminMoreView: View \{.*?(?=\nstruct AdminTripsView: View)", re.DOTALL)
new_text = admin_more_pattern.sub("", new_text)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(new_text)

