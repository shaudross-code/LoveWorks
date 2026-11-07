//
//  AdminDashboardView.swift
//  iLoveWorks
//

import SwiftUI
import Combine
import Charts


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

struct AdminDashboardMainView: View {
    @ObservedObject var viewModel: AdminViewModel
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OVERVIEW")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Theme.lovePink)
                            .tracking(1.5)
                        
                        Text("Today at a glance.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                        
                        Text("The numbers your foreman brain craves — workers on the clock, tasks in motion, money earned.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        AdminStatCard(label: "WORKERS", value: "\(viewModel.statsWorkersCount)", icon: "person.2.fill")
                        AdminStatCard(label: "ON THE CLOCK", value: "\(viewModel.statsActiveCount)", icon: "bolt.fill", accent: .green)
                        AdminStatCard(label: "HOURS LOGGED", value: String(format: "%.1f", viewModel.statsHoursLogged), icon: "clock.fill")
                        AdminStatCard(label: "TASKS ASSIGNED", value: "\(viewModel.statsTasksAssigned)", icon: "doc.plaintext.fill")
                        AdminStatCard(label: "COMPLETED", value: "\(viewModel.statsCompletedCount)", icon: "checkmark.seal.fill", accent: .green)
                        AdminStatCard(label: "TOTAL PAYROLL", value: "$\(Int(viewModel.statsTotalPayroll))", icon: "dollarsign.circle.fill")
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.forward.circle.fill")
                                        .foregroundStyle(Theme.lovePink)
                                    Text("Potential earnings")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Theme.textMain)
                                }
                                Text("If every worker completes all open tasks on schedule.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            Spacer()
                        }
                        .padding(20)
                        
                        Divider().background(Theme.border)
                        
                        VStack(spacing: 0) {
                            ForEach(viewModel.workerStatuses) { status in
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(status.worker.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Theme.textMain)
                                        HStack(spacing: 8) {
                                            Label("\(status.openTasksCount) open", systemImage: "calendar")
                                            if status.streakDays >= 2 {
                                                Text("🔥 \(status.streakDays)d streak")
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.textMuted)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .trailing) {
                                            Text("$\(Int(status.potentialWeekly))")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(Theme.primary)
                                        }
                                        
                                        Rectangle()
                                            .fill(Theme.border)
                                            .frame(width: 1, height: 16)
                                        
                                        VStack(alignment: .trailing) {
                                            Text("$\(Int(status.potentialMonthly))")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .padding(16)
                                if status.id != viewModel.workerStatuses.last?.id {
                                    Divider().background(Theme.border).padding(.leading, 16)
                                }
                            }
                        }
                    }
                    .background(Theme.surface)
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.lovePink.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            viewModel.loadDashboard()
        }
    }
}

struct AdminStatCard: View {
    let label: String
    let value: String
    let icon: String
    var accent: Color = Theme.primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(accent)
                }
            }
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textMain)
        }
        .padding(20)
        .background(Theme.surface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }
}

struct StatusPillView: View {
    let status: String
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").uppercased())
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bgColor())
            .foregroundStyle(textColor())
            .cornerRadius(100)
    }
    
    private func bgColor() -> Color {
        switch status {
        case "assigned": return Color.zinc.opacity(0.2)
        case "in_progress": return Theme.primary.opacity(0.1)
        case "completed": return Color.green.opacity(0.1)
        default: return Color.zinc.opacity(0.2)
        }
    }
    
    private func textColor() -> Color {
        switch status {
        case "assigned": return Theme.textMuted
        case "in_progress": return Theme.primary
        case "completed": return Color.green
        default: return Theme.textMuted
        }
    }
}

// MARK: - Management Views

struct AdminWorkersView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAddWorker = false
    @State private var editingWorker: User? = nil
    @State private var sizingWorker: User? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            PageHeader(eyebrow: "CREW · LIVE", title: "Your workers.")
                                .padding(.horizontal, 0)
                                .padding(.top, 0)
                            Spacer()
                            Button(action: { showingAddWorker = true }) {
                                Image(systemName: "person.badge.plus.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.workerStatuses) { status in
                                AdminWorkerCard(
                                    status: status,
                                    onEdit: { editingWorker = status.worker },
                                    onSizes: { sizingWorker = status.worker },
                                    onDelete: {
                                        Task {
                                            try? await viewModel.deleteWorker(workerId: status.worker.id)
                                        }
                                    }
                                )
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
            .sheet(item: $editingWorker) { worker in
                EditWorkerModal(worker: worker, viewModel: viewModel)
            }
            .sheet(item: $sizingWorker) { worker in
                WorkerSizesView(worker: worker)
            }
            .sheet(isPresented: $showingAddWorker) {
                AddWorkerView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadDashboard()
        }
    }
}

struct AdminWorkerCard: View {
    let status: WorkerStatus
    
    // Actions supplied by the parent list
    var onEdit: () -> Void = {}
    var onSizes: () -> Void = {}
    var onDelete: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    if let urlString = status.worker.avatarUrl, let url = URL(string: APIClient.shared.fullURL(for: urlString)) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle().fill(Theme.secondary)
                        }
                        .frame(width: 54, height: 50)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Theme.secondary)
                            .frame(width: 54, height: 54)
                            .overlay(Text(String(status.worker.name.prefix(1))).font(.headline))
                    }
                    
                    Circle()
                        .fill(status.online ? Theme.success : Color.gray)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Theme.surface, lineWidth: 2))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.worker.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textMain)
                    Text(status.currentlyClockedIn ? "Clocked in — \(status.activeActivity ?? "Working")" : "Off the clock")
                        .font(.system(size: 13))
                        .foregroundStyle(status.currentlyClockedIn ? Theme.lovePink : Theme.textMuted)
                }
                
                Spacer()
                
                // Actions exactly like web format
                HStack(spacing: 12) {
                    Button(action: onSizes) {
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            
            // Progress Bars for Hours
            HStack(spacing: 12) {
                HourProgressView(label: "TODAY", current: status.todayWorkedHours, target: status.dailyRequiredHours, left: status.todayLeftHours, color: Theme.lovePink)
                HourProgressView(label: "THIS WEEK", current: status.weekWorkedHours, target: status.weeklyRequiredHours, left: status.weekLeftHours, color: Theme.primary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 10))
                Text("\(status.openTasksCount) open task\(status.openTasksCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Theme.textMuted)
            
            // Weekly Strip
            WeeklyStrip(days: status.completionsByDay ?? [], streak: status.streakDays, title: "COMPLETED THIS WEEK")
                .padding(.top, 4)
            
            // Chips matching web implementation
            HStack(spacing: 8) {
                if status.isIdle == true {
                    Text("💤 IDLE \(status.idleMinutes ?? 0)M")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(Color.orange)
                        .cornerRadius(100)
                        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }
                if status.streakDays >= 2 {
                    Text("🔥 \(status.streakDays)-DAY STREAK")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(Color.orange)
                        .cornerRadius(100)
                        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }
                if status.inconsistencies?.streakBroken == true {
                    Text("⚠️ STREAK BROKEN")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(Color.orange)
                        .cornerRadius(100)
                        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }
                if !(status.inconsistencies?.missedDays ?? []).isEmpty {
                    Text("💤 \((status.inconsistencies?.missedDays ?? []).count) MISSED DAY\((status.inconsistencies?.missedDays ?? []).count == 1 ? "" : "S")")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.danger.opacity(0.15))
                        .foregroundStyle(Theme.danger)
                        .cornerRadius(100)
                        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.danger.opacity(0.3), lineWidth: 1))
                }
                if !(status.inconsistencies?.lowDays ?? []).isEmpty {
                    Text("📉 \((status.inconsistencies?.lowDays ?? []).count) LIGHT DAY\((status.inconsistencies?.lowDays ?? []).count == 1 ? "" : "S")")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surfaceHover)
                        .foregroundStyle(Theme.textMain)
                        .cornerRadius(100)
                        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.border, lineWidth: 1))
                }
                if status.streakDays == 0 && (status.inconsistencies?.totalIssues ?? 0) == 0 {
                    Text("✨ CLEAN WEEK")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.success.opacity(0.15))
                        .foregroundStyle(Theme.success)
                        .cornerRadius(100)
                        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.success.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Theme.surface)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1))
    }
}

struct HourProgressView: View {
    let label: String
    let current: Double
    let target: Double
    let left: Double?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1fh", current))
                    .font(.custom("Outfit-Bold", size: 20))
                    .foregroundStyle(.white)
                Text("/ \(String(format: "%.1fh", target))")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
            }
            
            if let left = left, left > 0 {
                Text("\(String(format: "%.1fh", left)) left")
                    .font(.system(size: 10))
                    .foregroundStyle(color)
            } else {
                Text("Target hit")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.success)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.surfaceHover)
                        .frame(height: 6)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(1.0, target > 0 ? current / target : 0)), height: 6)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
            .padding(.top, 4)
        }
        .padding()
        .background(Theme.surfaceHover)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}

struct InconsistencyChip: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 8, weight: .black))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .cornerRadius(6)
    }
}

struct AddWorkerView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var showingSizes = false
    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        TextField("Full Name", text: $name)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EMAIL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        TextField("worker@loveworks.com", text: $email)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TEMPORARY PASSWORD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        SecureField("••••••••", text: $password)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    Button(action: {
                        isSubmitting = true
                        Task {
                            try? await viewModel.createWorker(name: name, email: email, password: password)
                            await MainActor.run {
                                isSubmitting = false
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.loveGradient)
                        .foregroundStyle(.white)
                        .cornerRadius(100)
                    }
                    .disabled(isSubmitting || name.isEmpty || email.isEmpty || password.isEmpty)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Worker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AdminTasksView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAddTask = false
    @State private var editingTask: TaskItem? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PRICE & ASSIGN")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Tasks.")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                            Button(action: { showingAddTask = true }) {
                                Image(systemName: "plus.app.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.tasks.sorted { !$0.isCompleted && $1.isCompleted }) { task in
                                TaskRow(task: task, onToggle: {}, onStart: {}, onSpeak: { _ in })
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingTask = task }
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
            .sheet(item: $editingTask) { task in
                EditTaskModal(task: task, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadDashboard()
        }
    }
}

struct AddTaskView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var selectedWorkerId = ""
    @State private var isSubmitting = false
    @State private var showingSizes = false
    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TITLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        TextField("Task Name", text: $title)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        TextField("What needs to be done?", text: $description)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRICE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("0.00", text: $price)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASSIGNEE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            Picker("Worker", selection: $selectedWorkerId) {
                                Text("Select...").tag("")
                                ForEach(viewModel.workers) { worker in
                                    Text(worker.name).tag(worker.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Mandatory Alarm (Admin Only)", isOn: $setMandatoryAlarm)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                            .tint(Theme.lovePink)
                        
                        if setMandatoryAlarm {
                            DatePicker("Alarm Time", selection: $mandatoryAlarmTime, displayedComponents: .hourAndMinute)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textMain)
                        }
                    }
                    .padding()
                    .background(Theme.surface)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    
                    Button(action: {
                        isSubmitting = true
                        Task {
                            if let p = Double(price) {
                                
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let alarmStr = setMandatoryAlarm ? formatter.string(from: mandatoryAlarmTime) : nil
                                try? await viewModel.createTask(AdminViewModel.TaskCreateRequest(title: title, description: description, price: p, assigneeId: selectedWorkerId, frequency: "one-off", dueDayOfWeek: nil, dueTime: nil, adminAlarm: alarmStr))
                                await MainActor.run {
                                    isSubmitting = false
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Assign Task")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.loveGradient)
                        .foregroundStyle(.white)
                        .cornerRadius(100)
                    }
                    .disabled(isSubmitting || title.isEmpty || price.isEmpty || selectedWorkerId.isEmpty)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AdminGoalsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAddGoal = false
    @State private var editingGoal: Goal? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WISHLIST")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Goals.")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                            Button(action: { showingAddGoal = true }) {
                                Image(systemName: "target")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.goals) { goal in
                                GoalCard(goal: goal)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingGoal = goal }
                                        .onTapGesture { editingGoal = goal }
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
            .sheet(item: $editingGoal) { goal in
                EditGoalModal(goal: goal, isTrip: false, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(viewModel: viewModel, kind: "goal")
            }
        }
        .onAppear {
            viewModel.loadGoals()
            viewModel.loadDashboard()
        }
    }
}

struct AdminEssentialsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAdd = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EVERYDAY LIST")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Essentials.")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
                            Spacer()
                            Button(action: { showingAdd = true }) {
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.lovePink)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.essentials) { item in
                                EssentialCard(essential: item) {}
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
            .sheet(isPresented: $showingAdd) {
                AddEssentialView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadEssentials()
            viewModel.loadDashboard()
        }
    }
}

struct AddEssentialView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var price = ""
    @State private var quantity = "1"
    @State private var category = "household"
    @State private var ownerId = ""
    @State private var isSubmitting = false
    @State private var showingSizes = false
    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime = Date()
    
    let categories = ["household", "everyday", "groceries", "personal", "kids", "other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TITLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        TextField("What do we need?", text: $title)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRICE $")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("0.00", text: $price)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QTY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("1", text: $quantity)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { c in
                                Text(c.capitalized).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ASSIGN TO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        Picker("Worker", selection: $ownerId) {
                            Text("Select...").tag("")
                            ForEach(viewModel.workers) { worker in
                                Text(worker.name).tag(worker.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    Button(action: {
                        isSubmitting = true
                        Task {
                            if let p = Double(price), let q = Int(quantity) {
                                try? await viewModel.createEssential(title: title, price: p, quantity: q, category: category, ownerId: ownerId)
                                await MainActor.run {
                                    isSubmitting = false
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Add Item")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.loveGradient)
                        .foregroundStyle(.white)
                        .cornerRadius(100)
                    }
                    .disabled(isSubmitting || title.isEmpty || price.isEmpty || ownerId.isEmpty)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Essential")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AddGoalView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    let kind: String
    
    @State private var title = ""
    @State private var targetAmount = ""
    @State private var period = "weekly"
    @State private var ownerId = ""
    @State private var isSubmitting = false
    @State private var showingSizes = false
    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime = Date()
    
    let periods = ["daily", "weekly", "monthly", "yearly", "once"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TITLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        TextField("What is it?", text: $title)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARGET $")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("0", text: $targetAmount)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PERIOD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            Picker("Period", selection: $period) {
                                ForEach(periods, id: \.self) { p in
                                    Text(p.capitalized).tag(p)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ASSIGN TO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                        Picker("Worker", selection: $ownerId) {
                            Text("Select...").tag("")
                            ForEach(viewModel.workers) { worker in
                                Text(worker.name).tag(worker.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    }
                    
                    Button(action: {
                        isSubmitting = true
                        Task {
                            if let target = Double(targetAmount) {
                                try? await viewModel.createGoal(title: title, targetAmount: target, period: period, ownerId: ownerId, kind: kind)
                                await MainActor.run {
                                    isSubmitting = false
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text("Assign \(kind.capitalized)")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.loveGradient)
                        .foregroundStyle(.white)
                        .cornerRadius(100)
                    }
                    .disabled(isSubmitting || title.isEmpty || targetAmount.isEmpty || ownerId.isEmpty)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New \(kind.capitalized)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


struct AdminTripsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAdd = false
    @State private var editingTrip: Goal? = nil
    
    var body: some View {
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
                            Text("Travel plans.")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Theme.textMain)
                        }
                        Spacer()
                        Button(action: { showingAdd = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Theme.lovePink)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.trips) { trip in
                            GoalCard(goal: trip)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Trips")
        .sheet(isPresented: $showingAdd) {
            AddGoalView(viewModel: viewModel, kind: "trip")
        }
        .onAppear {
            viewModel.loadTrips()
        }
    }
}

struct AdminAnnouncementsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAdd = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            List {
                ForEach(viewModel.announcements) { ann in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(ann.title)
                                .font(.headline)
                                .foregroundStyle(Theme.textMain)
                            Spacer()
                            Text((ann.tag ?? "").uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.lovePink.opacity(0.15))
                                .cornerRadius(4)
                                .foregroundStyle(Theme.lovePink)
                        }
                        Text(ann.body)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Announcements")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.lovePink)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddAnnouncementView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadAnnouncements()
        }
    }
}

struct AddAnnouncementView: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tag = "announcement"
    
    let tags = ["announcement", "feature", "update", "maintenance"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    TextField("Title", text: $title)
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(12)
                    
                    TextEditor(text: $bodyText)
                        .frame(height: 150)
                        .padding(8)
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                    
                    Picker("Tag", selection: $tag) {
                        ForEach(tags, id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Button("Broadcast") {
                        Task {
                            try? await viewModel.createAnnouncement(title: title, body: bodyText, tag: tag)
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.loveGradient)
                    .foregroundStyle(.white)
                    .cornerRadius(100)
                    .font(.headline)
                    .disabled(title.isEmpty || bodyText.isEmpty)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Announcement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AdminPayrollView: View {
    @ObservedObject var viewModel: AdminViewModel
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            List {
                ForEach(viewModel.payroll) { row in
                    HStack(spacing: 16) {
                        if let urlString = row.worker.avatarUrl, let url = URL(string: APIClient.shared.fullURL(for: urlString)) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Theme.secondary)
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.secondary)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(row.worker.name.prefix(1)))
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Theme.textMain)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.worker.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.textMain)
                            Text("\(row.tasksCompleted) tasks completed • \(String(format: "%.1f", row.totalHours))h worked")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                        }
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", row.tasksEarnings))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.success)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.border)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Payroll")
        .onAppear {
            viewModel.loadDashboard()
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(SessionManager.shared)
}



struct AdminSettingsView: View {
    @AppStorage("useMetric") private var useMetric = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    PageHeader(eyebrow: "COMPANY OPTIONS", title: "Settings.")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Regional Options")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Global Measurement System")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Theme.textMain)
                                    Text(useMetric ? "Metric" : "Imperial / U.S.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.lovePink)
                                }
                                Spacer()
                                Toggle("", isOn: $useMetric)
                                    .tint(Theme.lovePink)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal)
                        }
                        .background(Theme.surface)
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
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

struct EditWorkerModal: View {
    let worker: User
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var email: String
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var showingSizes = false
    
    init(worker: User, viewModel: AdminViewModel) {
        self.worker = worker
        self.viewModel = viewModel
        _name = State(initialValue: worker.name)
        _email = State(initialValue: worker.email)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let urlString = worker.avatarUrl, let url = URL(string: APIClient.shared.fullURL(for: urlString)) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Theme.secondary)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .padding(.top, 40)
                        } else {
                            Circle()
                                .fill(Theme.secondary)
                                .frame(width: 80, height: 80)
                                .overlay(Text(String(worker.name.prefix(1))).font(.title).bold())
                                .padding(.top, 40)
                        }
                            
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NAME")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Name", text: $name)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEW PASSWORD (OPTIONAL)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            SecureField("Enter new password", text: $password)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                                .padding(.bottom, 20)
                        }
                        
                        Button(action: { showingSizes = true }) {
                            HStack {
                                Image(systemName: "ruler.fill")
                                Text("VIEW & EDIT SIZES")
                                    .font(.system(size: 14, weight: .black))
                                    .tracking(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.surface)
                            .foregroundStyle(Theme.textMain)
                            .cornerRadius(100)
                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(Theme.border, lineWidth: 1))
                        }
                        .sheet(isPresented: $showingSizes) {
                            WorkerSizesView(worker: worker)
                        }

                        Button(action: saveChanges) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("SAVE EDITS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.loveGradient)
                            .foregroundStyle(.white)
                            .cornerRadius(100)
                        }
                        .disabled(isSubmitting || name.isEmpty || email.isEmpty)
                        
                        Button(action: deleteWorker) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("REMOVE WORKER PERMANENTLY")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(100)
                        }
                        .disabled(isSubmitting)
                        .padding(.top, 40)
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Manage Worker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSubmitting = true
        let req = AdminViewModel.WorkerUpdateRequest(
            name: name,
            email: email,
            password: password.isEmpty ? nil : password
        )
        Task {
            try? await viewModel.updateWorker(workerId: worker.id, req: req)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteWorker() {
        isSubmitting = true
        Task {
            try? await viewModel.deleteWorker(workerId: worker.id)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditTaskModal: View {
    let task: TaskItem
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var price: String
    @State private var selectedWorkerId: String
    @State private var adminAlarm: String?
    @State private var setMandatoryAlarm: Bool
    @State private var mandatoryAlarmTime: Date
    @State private var frequency: String
    @State private var payoutSchedule: String
    @State private var isSubmitting = false
    @State private var showingSizes = false
    
    init(task: TaskItem, viewModel: AdminViewModel) {
        self.task = task
        self.viewModel = viewModel
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _price = State(initialValue: String(format: "%.2f", task.price))
        _selectedWorkerId = State(initialValue: task.assigneeId)
        _frequency = State(initialValue: task.frequency ?? "once")
        _payoutSchedule = State(initialValue: task.payoutSchedule ?? "per_task")
        
        let hasAlarm = task.adminAlarm != nil
        _setMandatoryAlarm = State(initialValue: hasAlarm)
        _adminAlarm = State(initialValue: task.adminAlarm)
        
        if let alarmStr = task.adminAlarm, let hr = Int(alarmStr.prefix(2)), let min = Int(alarmStr.suffix(2)) {
            var comps = DateComponents()
            comps.hour = hr
            comps.minute = min
            let d = Calendar.current.date(from: comps) ?? Date()
            _mandatoryAlarmTime = State(initialValue: d)
        } else {
            _mandatoryAlarmTime = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Task Name", text: $title)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION (OPTIONAL)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("Details", text: $description)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BOUNTY PRICE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("0.00", text: $price)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FREQUENCY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.textMuted)
                                Picker("Frequency", selection: $frequency) {
                                    ForEach(["once", "daily", "weekly", "monthly"], id: \.self) { f in Text(f.capitalized).tag(f) }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PAYOUT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.textMuted)
                                Picker("Payout Schedule", selection: $payoutSchedule) {
                                    ForEach(["per_task", "daily", "weekly", "monthly"], id: \.self) { p in Text(p.replacingOccurrences(of: "_", with: " ").capitalized).tag(p) }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASSIGN TO WORKER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            Menu {
                                Button("Any / Open Pool") { selectedWorkerId = "" }
                                ForEach(viewModel.workers) { w in
                                    Button(w.name) { selectedWorkerId = w.id }
                                }
                            } label: {
                                HStack {
                                    Text(selectedWorkerId.isEmpty ? "Select Worker" : (viewModel.workers.first(where: { $0.id == selectedWorkerId })?.name ?? "Unknown"))
                                        .foregroundStyle(selectedWorkerId.isEmpty ? Theme.textMuted : Theme.textMain)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("SET MANDATORY ALARM", isOn: $setMandatoryAlarm)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                                .tint(Theme.lovePink)
                            
                            if setMandatoryAlarm {
                                DatePicker("Alarm Time", selection: $mandatoryAlarmTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.graphical)
                                    .padding()
                                    .background(Theme.surface)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        
                        Button(action: saveChanges) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("SAVE EDITS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.loveGradient)
                            .foregroundStyle(.white)
                            .cornerRadius(100)
                        }
                        .disabled(isSubmitting || title.isEmpty)
                        
                        Button(action: deleteTask) {
                            Text("DELETE TASK")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.red)
                                .padding()
                        }
                        .disabled(isSubmitting)
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSubmitting = true
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let alarmStr = setMandatoryAlarm ? formatter.string(from: mandatoryAlarmTime) : nil
        
        let req = AdminViewModel.TaskUpdateRequest(
            title: title.isEmpty ? nil : title,
            description: description,
            price: Double(price),
            assigneeId: selectedWorkerId.isEmpty ? nil : selectedWorkerId,
            frequency: frequency,
            payoutSchedule: payoutSchedule,
            adminAlarm: alarmStr
        )
        
        Task {
            try? await viewModel.updateTask(taskId: task.id, req: req)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteTask() {
        isSubmitting = true
        Task {
            try? await viewModel.deleteTask(taskId: task.id)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditGoalModal: View {
    let goal: Goal
    let isTrip: Bool
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var targetAmount: String
    @State private var period: String
    @State private var ownerId: String
    @State private var productLink: String
    @State private var imageUrl: String
    @State private var isSubmitting = false
    @State private var showingSizes = false
    
    init(goal: Goal, isTrip: Bool, viewModel: AdminViewModel) {
        self.goal = goal
        self.isTrip = isTrip
        self.viewModel = viewModel
        _title = State(initialValue: goal.title)
        _targetAmount = State(initialValue: String(format: "%.2f", goal.targetAmount ?? 0.0))
        _period = State(initialValue: goal.period ?? "")
        _ownerId = State(initialValue: goal.ownerId)
        _productLink = State(initialValue: goal.productLink ?? "")
        _imageUrl = State(initialValue: goal.imageUrl ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("What is it?", text: $title)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARGET AMOUNT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("0.00", text: $targetAmount)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRODUCT LINK URL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("https://...", text: $productLink)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("IMAGE URL (HDPI)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("https://...", text: $imageUrl)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASSIGN TO WORKER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            Menu {
                                Button("Any / Open Pool") { ownerId = "" }
                                ForEach(viewModel.workers) { w in
                                    Button(w.name) { ownerId = w.id }
                                }
                            } label: {
                                HStack {
                                    Text(ownerId.isEmpty ? "Select Worker" : (viewModel.workers.first(where: { $0.id == ownerId })?.name ?? "Unknown"))
                                        .foregroundStyle(ownerId.isEmpty ? Theme.textMuted : Theme.textMain)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DUE DATE / NOTE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textMuted)
                            TextField("e.g. Next Friday", text: $period)
                                .padding()
                                .background(Theme.surface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                                .foregroundStyle(Theme.textMain)
                        }
                        
                        Button(action: saveChanges) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("SAVE EDITS")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.loveGradient)
                            .foregroundStyle(.white)
                            .cornerRadius(100)
                        }
                        .disabled(isSubmitting || title.isEmpty)
                        
                        Button(action: deleteGoal) {
                            Text(isTrip ? "DELETE TRIP" : "DELETE GOAL")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.red)
                                .padding()
                        }
                        .disabled(isSubmitting)
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle(isTrip ? "Edit Trip" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }
    
    private func saveChanges() {
        isSubmitting = true
        let req = AdminViewModel.GoalUpdateRequest(
            title: title.isEmpty ? nil : title,
            targetAmount: Double(targetAmount),
            period: period.isEmpty ? nil : period,
            ownerId: ownerId.isEmpty ? nil : ownerId,
            productLink: productLink.isEmpty ? nil : productLink,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl
        )
        Task {
            try? await viewModel.updateGoal(goalId: goal.id, req: req)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteGoal() {
        isSubmitting = true
        Task {
            try? await viewModel.deleteGoal(goalId: goal.id)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}


struct WeeklyStrip: View {
    let days: [DailyCompletion]
    let streak: Int
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                if streak >= 2 {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(streak)-DAY STREAK")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                    .foregroundStyle(.black)
                    .cornerRadius(100)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                }
            }
            
            HStack(spacing: 6) {
                let currentDayIndex = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
                let streakSet = Set((0..<streak).map { (currentDayIndex - $0 + 7) % 7 })
                
                ForEach(0..<7, id: \.self) { i in
                    let dayObj = i < days.count ? days[i] : nil
                    let has = (dayObj?.count ?? 0) > 0
                    let isToday = i == currentDayIndex
                    let isStreak = streakSet.contains(i) && has
                    
                    VStack(spacing: 2) {
                        if isStreak {
                            Text("🔥")
                                .font(.system(size: 8))
                                .offset(x: 10, y: -4)
                        }
                        Text(dayObj?.day ?? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][i])
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(has ? .black : Theme.textMuted)
                            .textCase(.uppercase)
                            .tracking(1)
                            .opacity(has ? 0.8 : 1.0)
                        
                        Text("\(dayObj?.count ?? 0)")
                            .font(.custom("Outfit-Bold", size: 16))
                            .foregroundStyle(has ? .black : Theme.textMuted.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if has {
                                LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            } else {
                                Theme.surface.opacity(0.6)
                            }
                        }
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(has ? .yellow : Theme.border, lineWidth: isToday ? 2 : 1)
                    )
                }
            }
        }
    }
}
