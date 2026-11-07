import Foundation

let path = "iLoveWorks/AdminDashboardView.swift"
var fileStr = try! String(contentsOfFile: path, encoding: .utf8)

let targetStructPattern = """
struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            AdminDashboardMainView(viewModel: viewModel)
                .tabItem { Label("Overview", systemImage: "chart.bar.fill") }
            
            AdminWorkersView(viewModel: viewModel)
                .tabItem { Label("Crew", systemImage: "person.2.fill") }
            
            AdminTasksView(viewModel: viewModel)
                .tabItem { Label("Tasks", systemImage: "checklist") }
            
            AdminEssentialsView(viewModel: viewModel)
                .tabItem { Label("Essentials", systemImage: "cart.fill") }
            
            AdminMoreView(viewModel: viewModel)
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .accentColor(Theme.lovePink)
        .onAppear {
#if canImport(UIKit)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
#endif
        }
    }
}
"""

let customTabStruct = """
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
                                Task { await sessionManager.logout() }
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
                        AdminGoalsPlaceholder()
                    case .trips:
                        AdminTripsPlaceholder()
                    case .essentials:
                        AdminEssentialsView(viewModel: viewModel)
                    case .payroll:
                        AdminPayrollPlaceholder()
                    case .announcements:
                        AdminAnnouncementsPlaceholder()
                    case .sizes:
                        MySizesView()
                    case .profile:
                        AdminProfilePlaceholder()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// Temporary Placeholders to avoid build failures until those screens are built natively
struct AdminGoalsPlaceholder: View { var body: some View { Text("Goals coming soon natively!").foregroundStyle(.gray) } }
struct AdminTripsPlaceholder: View { var body: some View { Text("Trips coming soon natively!").foregroundStyle(.gray) } }
struct AdminPayrollPlaceholder: View { var body: some View { Text("Payroll coming soon natively!").foregroundStyle(.gray) } }
struct AdminAnnouncementsPlaceholder: View { var body: some View { Text("Announcements coming soon natively!").foregroundStyle(.gray) } }
struct AdminProfilePlaceholder: View { var body: some View { Text("Profile coming soon natively!").foregroundStyle(.gray) } }
"""

if fileStr.contains("TabView") {
    if fileStr.contains(targetStructPattern) {
        fileStr = fileStr.replacingOccurrences(of: targetStructPattern, with: customTabStruct)
        try! fileStr.write(toFile: path, atomically: true, encoding: .utf8)
        print("Updated tabs to custom horizontal scroll!")
    } else {
        print("Could not match exact target pattern. Injecting manually.")
        // Harder override...
    }
} else {
    print("TabView not found.")
}
