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
    
    static func info(for id: String) -> ActivityInfo {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

struct WorkerDashboardView: View {
    @StateObject private var viewModel = WorkerViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        TabView {
            WorkerDashboardMainView(viewModel: viewModel)
                .tabItem { Label("Workday", systemImage: "bolt.heart.fill") }
            
            WorkerEssentialsView(viewModel: viewModel)
                .tabItem { Label("Essentials", systemImage: "cart.fill") }
            
            WorkerTripsView(viewModel: viewModel)
                .tabItem { Label("Trips", systemImage: "airplane") }
            
            WorkerAwardsView(viewModel: viewModel)
                .tabItem { Label("Awards", systemImage: "trophy.fill") }
            
            WorkerProfileView(viewModel: viewModel)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
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

struct WorkerDashboardMainView: View {
    @ObservedObject var viewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isPulsing = false
    @State private var showingNotifications = false
    @State private var showingPicker = false
    
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
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

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
                            
                            let earnings = viewModel.tasks.filter { $0.status == "completed" }.reduce(0) { $0 + $1.price }
                            let openPotential = viewModel.tasks.filter { $0.status != "completed" }.reduce(0) { $0 + $1.price }
                            let todaySeconds = calculateTodaySeconds()
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                Tile(label: "SHIFT", value: formatDuration(viewModel.liveSeconds))
                                Tile(label: "TODAY", value: String(format: "%.2fh", Double(todaySeconds) / 3600.0))
                                Tile(label: "OPEN", value: "\(viewModel.tasks.filter { $0.status != "completed" }.count)")
                                Tile(label: "EARNED", value: "$\(Int(earnings))", icon: nil, accentColor: Theme.lovePink)
                                Tile(label: "POTENTIAL", value: "$\(Int(openPotential))", icon: nil, accentColor: Theme.lovePink)
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
                                                Text(formatDuration(viewModel.liveSeconds))
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
                                            
                                            Button(action: { Task { try? await viewModel.clockOut() } }) {
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

                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        let overdue = viewModel.tasks.filter { $0.status != "completed" && isOverdue($0) }
                        let dueToday = viewModel.tasks.filter { $0.status != "completed" && isDueToday($0) }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DeadlineBucket(title: "Overdue", tasks: overdue, tone: .red, icon: "exclamationmark.triangle.fill")
                            DeadlineBucket(title: "Due Today", tasks: dueToday, tone: .yellow, icon: "calendar")
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Your tasks")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.textMain)
                            Spacer()
                            Text("\(viewModel.tasks.filter { $0.status != "completed" }.count) open · \(viewModel.tasks.filter { $0.status == "completed" }.count) done")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                                .tracking(0.5)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if viewModel.tasks.isEmpty {
                                EmptyStateView(icon: "sparkles", title: "No tasks yet", message: "Your admin will assign them here.")
                            } else {
                                ForEach(viewModel.tasks) { task in
                                    TaskRow(task: task, onToggle: {
                                        Task { try? await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "completed" ? "assigned" : "completed") }
                                    }, onStart: {
                                        Task { try? await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "in_progress" ? "assigned" : "in_progress") }
                                    }, onSpeak: { speak($0) })
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

                    GoalsCardView(goals: viewModel.goals)
                        .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(notifications: viewModel.notifications)
        }
    }
    
    private func calculateTodaySeconds() -> Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        return viewModel.allEntries.filter {
            if let d = formatter.date(from: $0.clockIn) {
                return d >= startOfToday
            }
            return false
        }.reduce(0) { $0 + $1.durationSeconds }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    
    private func isOverdue(_ task: TaskItem) -> Bool {
        guard let due = task.dueAt else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: due) else { return false }
        return date < Date()
    }
    
    private func isDueToday(_ task: TaskItem) -> Bool {
        guard let due = task.dueAt else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: due) else { return false }
        return Calendar.current.isDateInToday(date)
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
                            await MainActor.run { onSelected() }
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
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("STOCK UP")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Essentials")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        if viewModel.essentials.isEmpty {
                            EmptyStateView(icon: "cart.badge.plus", title: "List is empty", message: "Items shared with you will appear here.")
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.essentials) { item in
                                    EssentialCard(essential: item) {
                                        // Toggle purchased logic
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

struct WorkerTripsView: View {
    @ObservedObject var viewModel: WorkerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ADVENTURE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Trips")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        if viewModel.trips.isEmpty {
                            EmptyStateView(icon: "airplane.circle.fill", title: "No trips planned", message: "Start saving toward your next getaway.")
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.trips) { trip in
                                    GoalCard(goal: trip)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

struct WorkerAwardsView: View {
    @ObservedObject var viewModel: WorkerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ACHIEVEMENTS")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Trophy Case")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.awards) { award in
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(award.earned ? Theme.lovePink : Theme.secondary.opacity(0.5))
                                            .frame(width: 80, height: 80)
                                        
                                        Text(award.icon)
                                            .font(.system(size: 40))
                                            .grayscale(award.earned ? 0 : 1)
                                            .opacity(award.earned ? 1 : 0.4)
                                    }
                                    
                                    VStack(spacing: 4) {
                                        Text(award.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(award.earned ? Theme.textMain : Theme.textMuted)
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
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

struct WorkerProfileView: View {
    @ObservedObject var viewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.loveGradient)
                                    .frame(width: 120, height: 120)
                                
                                Text(String(sessionManager.currentUser?.name.prefix(1) ?? "W"))
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text(sessionManager.currentUser?.name ?? "Worker")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                                Text(sessionManager.currentUser?.email ?? "")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Sections
                        VStack(spacing: 20) {
                            Button(action: { sessionManager.logout() }) {
                                HStack {
                                    Image(systemName: "power")
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.surface)
                                .foregroundStyle(Theme.lovePink)
                                .cornerRadius(100)
                                .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.lovePink.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
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
                        .font(.system(size: 8))
                }
                Text(label)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surface.opacity(0.6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
}

struct GoalsCardView: View {
    let goals: [Goal]
    
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
                    GoalCard(goal: goal)
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
