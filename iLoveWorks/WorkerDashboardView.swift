//
//  WorkerDashboardView.swift
//  iLoveWorks
//

import SwiftUI
import AVFoundation

struct ActivityInfo: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
    let bg: Color

    static let all = [
        ActivityInfo(id: "working", label: "Working", icon: "briefcase.fill", color: .white, bg: Theme.lovePink),
        ActivityInfo(id: "break", label: "Break", icon: "cup.and.saucer.fill", color: .white, bg: .blue),
        ActivityInfo(id: "cleaning", label: "Cleaning", icon: "bubbles.and.sparkles.fill", color: .white, bg: .green),
        ActivityInfo(id: "parenting", label: "Parenting", icon: "figure.2.and.child.holdinghands", color: .white, bg: .purple),
        ActivityInfo(id: "studying", label: "Studying", icon: "book.fill", color: .white, bg: .orange),
        ActivityInfo(id: "workout", label: "Workout", icon: "figure.run", color: .white, bg: .red),
        ActivityInfo(id: "self_care", label: "Self Care", icon: "sparkles", color: .white, bg: .cyan)
    ]

    static func info(for id: String?) -> ActivityInfo {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

enum WorkerTab: String, CaseIterable, Identifiable {
    case workday = "Workday"
    case history = "History"
    case goals = "Goals"
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
        case .goals: return "target"
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
                    case .goals:
                        WorkerGoalsView(viewModel: viewModel)
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

struct WorkerDashboardMainView: View {
    @ObservedObject var viewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isPulsing = false
    @State private var showingNotifications = false
    @State private var showingPicker = false
    @State private var actionError: String?

    let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textMuted)
                            Text(sessionManager.currentUser?.name ?? "Worker")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Theme.textMain)
                        }

                        Spacer()

                        HolidayBadge(compact: true)

                        Button(action: { showingNotifications = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.textMain)

                                if viewModel.unreadNotificationsCount > 0 {
                                    Circle()
                                        .fill(Theme.lovePink)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
                            .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Notifications")
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    if let err = viewModel.loadError ?? actionError {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.danger)
                            .padding(.horizontal)
                    }

                    // Hero Section
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 8) {
                                if viewModel.activeEntries.isEmpty {
                                    Text("READY TO START")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(Theme.lovePink)
                                        .tracking(1.5)
                                } else {
                                    Text("CURRENTLY")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(Theme.lovePink)
                                        .tracking(1.5)

                                    ForEach(viewModel.activeEntries) { entry in
                                        let info = ActivityInfo.info(for: entry.activity)
                                        HStack(spacing: 4) {
                                            Image(systemName: info.icon)
                                                .font(.system(size: 8))
                                            Text(info.label.uppercased())
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(info.bg.opacity(0.15))
                                        .foregroundStyle(info.bg)
                                        .cornerRadius(100)
                                    }
                                }
                            }

                            Text(viewModel.activeEntries.count > 1 ? "You're juggling \(viewModel.activeEntries.count) clocks." : (viewModel.activeEntries.count == 1 ? "You're on the clock." : "Punch in to begin."))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Theme.textMain)

                            let earnings = viewModel.tasks.filter { $0.isCompleted }.reduce(0) { $0 + $1.price }
                            let deadlines = viewModel.deadlines

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                Tile(label: "SHIFT", value: Fmt.clock(viewModel.liveSeconds))
                                Tile(label: "TODAY", value: String(format: "%.2fh", viewModel.todayHours))
                                Tile(label: "OPEN", value: "\(viewModel.tasks.filter { !$0.isCompleted }.count)")
                                Tile(label: "EARNED", value: "$\(Int(earnings))", icon: nil, accentColor: Theme.lovePink)
                                Tile(label: "THIS WEEK", value: "$\(Int(deadlines.weeklyPotential))", icon: nil, accentColor: Theme.primary)
                                Tile(label: "STREAK", value: "\(viewModel.streakDays)d", icon: "flame.fill", accentColor: .orange)
                            }

                            HStack {
                                Spacer()
                                if viewModel.activeEntries.isEmpty {
                                    Button(action: { showingPicker.toggle() }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 32))
                                            Text("Clock In")
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                        .frame(width: 144, height: 144)
                                        .background(Theme.loveGradient)
                                        .foregroundStyle(.white)
                                        .clipShape(Circle())
                                        .shadow(color: Theme.lovePink.opacity(0.4), radius: 20, y: 10)
                                        .scaleEffect(isPulsing ? 1.05 : 1.0)
                                    }
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                            isPulsing = true
                                        }
                                    }
                                } else {
                                    let primaryInfo = ActivityInfo.info(for: viewModel.activeEntries[0].activity)
                                    VStack(spacing: 20) {
                                        ZStack {
                                            Circle()
                                                .stroke(primaryInfo.bg.opacity(0.15), lineWidth: 6)
                                                .frame(width: 144, height: 144)

                                            VStack(spacing: 4) {
                                                Image(systemName: primaryInfo.icon)
                                                    .font(.system(size: 24))
                                                Text(primaryInfo.label.uppercased())
                                                    .font(.system(size: 10, weight: .black))
                                                    .tracking(1)
                                                Text(Fmt.clock(viewModel.liveSeconds))
                                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                            }
                                            .foregroundStyle(primaryInfo.bg)
                                        }

                                        HStack(spacing: 12) {
                                            Button(action: { showingPicker.toggle() }) {
                                                Label("Start Another", systemImage: "plus")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(Theme.surface)
                                                    .foregroundStyle(Theme.textMain)
                                                    .cornerRadius(100)
                                                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.border, lineWidth: 1))
                                            }

                                            Button(action: { run { try await viewModel.clockOut() } }) {
                                                Label("Stop All", systemImage: "square.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(Color.red.opacity(0.1))
                                                    .foregroundStyle(.red)
                                                    .cornerRadius(100)
                                                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.red.opacity(0.3), lineWidth: 1))
                                            }
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(24)
                        .background(Theme.surface)
                        .cornerRadius(32)
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Theme.lovePink.opacity(0.15), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    if showingPicker {
                        ActivityPickerView(viewModel: viewModel) { showingPicker = false }
                            .padding(.horizontal)
                    }

                    deadlinesSection

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Your tasks")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.textMain)
                            Spacer()
                            Text("\(viewModel.tasks.filter { !$0.isCompleted }.count) open · \(viewModel.tasks.filter { $0.isCompleted }.count) done")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                                .tracking(0.5)
                        }
                        .padding(.horizontal)

                        VStack(spacing: 8) {
                            if viewModel.tasks.isEmpty {
                                EmptyStateView(icon: "sparkles", title: "No tasks yet", message: "Your admin will assign them here.")
                            } else {
                                ForEach(viewModel.tasks.sorted { !$0.isCompleted && $1.isCompleted }) { task in
                                    TaskRow(task: task, onToggle: {
                                        run { try await viewModel.updateTaskStatus(taskId: task.id, status: task.isCompleted ? "assigned" : "completed") }
                                    }, onStart: {
                                        run { try await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "in_progress" ? "assigned" : "in_progress") }
                                    }, onSpeak: { speak($0) }, onSaveAlarm: { alarm in 
                                        run { try await viewModel.updateTaskAlarm(taskId: task.id, alarmTime: alarm, taskTitle: task.title) }
                                    })
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("YOUR WEEK")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                            .tracking(1.5)
                            .padding(.horizontal)

                        WeeklyStripView(activity: viewModel.weeklyActivity)
                            .padding(.horizontal)
                    }

                    GoalsCardView(goals: viewModel.goals) { id, reactions in
                        viewModel.setReactions(goalId: id, reactions)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .refreshable { await viewModel.refresh() }
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(notifications: viewModel.notifications) { viewModel.markNotificationsRead() }
        }
    }

    private var deadlinesSection: some View {
        let d = viewModel.deadlines
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.lovePink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deadlines")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textMain)
                    Text("What needs to ship today and this week.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DeadlineBucket(title: "Overdue", tasks: d.overdue, tone: .red, icon: "exclamationmark.triangle.fill")
                DeadlineBucket(title: "Due Today", tasks: d.dueToday, tone: .yellow, icon: "calendar")
                DeadlineBucket(title: "This Week", tasks: d.dueThisWeek, tone: .sky, icon: "calendar.badge.clock")
                DeadlineBucket(title: "Open · Later", tasks: d.later, tone: .zinc, icon: "tray")
            }
            .padding(.horizontal)
        }
    }

    private func run(_ action: @escaping () async throws -> Void) {
        Task {
            do { try await action(); actionError = nil }
            catch { actionError = error.localizedDescription }
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
}

// MARK: - Subviews

struct ActivityPickerView: View {
    @ObservedObject var viewModel: WorkerViewModel
    let onSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.activeEntries.isEmpty ? "WHAT ARE YOU DOING?" : "ADD ANOTHER CLOCK")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ActivityInfo.all) { info in
                    let isRunning = viewModel.activeEntries.contains(where: { $0.activity == info.id })
                    Button(action: {
                        Task {
                            try? await viewModel.clockIn(activity: info.id)
                            onSelected()
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(info.bg.opacity(isRunning ? 0.05 : 0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: info.icon)
                                    .foregroundStyle(info.bg)
                            }
                            Text(info.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isRunning ? Theme.textMuted : Theme.textMain)
                            if isRunning {
                                Text("RUNNING")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.surface)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isRunning ? Theme.lovePink.opacity(0.3) : Theme.border, lineWidth: 1))
                    }
                    .disabled(isRunning)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Theme.lovePink)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Theme.surface)
        .cornerRadius(24)
    }
}

struct WorkerEssentialsView: View {
    @ObservedObject var viewModel: WorkerViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeader(eyebrow: "STOCK UP", title: "Essentials")

                        if viewModel.essentials.isEmpty {
                            EmptyStateView(icon: "cart.badge.plus", title: "List is empty", message: "Items shared with you will appear here.")
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.essentials) { item in
                                    EssentialCard(essential: item) {}
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .refreshable { await viewModel.refresh() }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}

struct WorkerTripsView: View {
    @ObservedObject var viewModel: WorkerViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PageHeader(eyebrow: "ADVENTURE", title: "Trips")

                        if viewModel.trips.isEmpty {
                            EmptyStateView(icon: "airplane.circle.fill", title: "No trips planned", message: "Start saving toward your next getaway.")
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.trips) { trip in
                                    GoalCard(goal: trip) { viewModel.setReactions(goalId: trip.id, $0) }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 40)
                    }
                }
                .refreshable { await viewModel.refresh() }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
        }
    }
}

/// Trophy case — opened from Profile.
struct WorkerAwardsView: View {
    @ObservedObject var viewModel: WorkerViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeader(eyebrow: "ACHIEVEMENTS", title: "Trophy Case")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.awards) { award in
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(award.earned ? Theme.lovePink : Theme.secondary.opacity(0.5))
                                        .frame(width: 80, height: 80)

                                    Image(systemName: Self.symbol(for: award.icon))
                                        .font(.system(size: 34))
                                        .foregroundStyle(award.earned ? .white : Theme.textMuted)
                                        .opacity(award.earned ? 1 : 0.5)
                                }

                                VStack(spacing: 4) {
                                    Text(award.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(award.earned ? Theme.textMain : Theme.textMuted)
                                        .multilineTextAlignment(.center)
                                    Text(award.description)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textMuted)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.surface)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(award.earned ? Theme.lovePink.opacity(0.3) : Theme.border, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Trophy case")
        .inlineNavigationTitle()
    }

    /// Server icon names → SF Symbols.
    static func symbol(for icon: String) -> String {
        switch icon {
        case "flame": return "flame.fill"
        case "flame-gold": return "flame.circle.fill"
        case "high-five": return "hands.clap.fill"
        case "medal-bronze", "medal-silver", "medal-gold": return "medal.fill"
        case "sparkle": return "sparkles"
        case "sunrise": return "sunrise.fill"
        case "trophy": return "trophy.fill"
        default: return "star.fill"
        }
    }
}

struct PageHeader: View {
    let eyebrow: String
    let title: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Theme.lovePink)
                    .tracking(1.5)
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.textMain)
            }
            Spacer()
            HolidayBadge(compact: true)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

struct Tile: View {
    let label: String
    let value: String
    var icon: String? = nil
    var accentColor: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }
                Text(label)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(.custom("Outfit-Bold", size: 24))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(red: 24/255, green: 24/255, blue: 27/255).opacity(0.7))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 39/255, green: 39/255, blue: 42/255), lineWidth: 1))
    }
}

struct GoalsCardView: View {
    let goals: [Goal]
    var onReactionsChange: ((String, [GoalReaction]) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Active Goals")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textMain)

            if goals.isEmpty {
                Text("No goals yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            } else {
                ForEach(goals) { goal in
                    if let onReactionsChange {
                        GoalCard(goal: goal) { onReactionsChange(goal.id, $0) }
                    } else {
                        GoalCard(goal: goal)
                    }
                }
            }
        }
    }
}

struct ProfileRow<Content: View>: View {
    let icon: String
    let label: String
    let color: Color
    let trailing: () -> Content

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textMain)

            Spacer()

            trailing()
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
}

#Preview {
    WorkerDashboardView()
        .environmentObject(SessionManager.shared)
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
                            Text("\(String(format: "%.1f", hours))h").bold().foregroundStyle(Theme.textMain)
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



struct WorkerGoalsView: View {
    @ObservedObject var viewModel: WorkerViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeader(eyebrow: "WISHLIST", title: "Target Goals.")

                    VStack(spacing: 12) {
                        if viewModel.goals.isEmpty {
                            Text("No active goals found.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textMuted)
                                .padding()
                        } else {
                            ForEach(viewModel.goals) { goal in
                                GoalCard(goal: goal, onReactionsChange: { newReactions in
                                    viewModel.setReactions(goalId: goal.id, newReactions)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
