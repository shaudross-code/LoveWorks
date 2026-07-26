//
//  AdminDashboardView.swift
//  iLoveWorks
//

import SwiftUI
import Combine
import Charts

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
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CREW · LIVE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Theme.lovePink)
                                    .tracking(1.5)
                                Text("Your workers.")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.textMain)
                            }
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
                                AdminWorkerCard(status: status)
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
                
                if status.streakDays >= 1 {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(status.streakDays)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Progress Bars for Hours
            HStack(spacing: 16) {
                HourProgressView(label: "TODAY", current: status.todayWorkedHours, target: status.dailyRequiredHours, color: Theme.lovePink)
                HourProgressView(label: "WEEK", current: status.weekWorkedHours, target: status.weeklyRequiredHours, color: Theme.primary)
            }
            
            // Inconsistency Chips
            if status.inconsistencies.totalIssues > 0 {
                HStack(spacing: 8) {
                    if status.inconsistencies.streakBroken {
                        InconsistencyChip(label: "STREAK BROKEN", icon: "exclamationmark.triangle.fill", color: .red)
                    }
                    if !status.inconsistencies.missedDays.isEmpty {
                        InconsistencyChip(label: "\(status.inconsistencies.missedDays.count) MISSED DAYS", icon: "zzz", color: .blue)
                    }
                    if !status.inconsistencies.lowDays.isEmpty {
                        InconsistencyChip(label: "\(status.inconsistencies.lowDays.count) LIGHT DAYS", icon: "chart.line.downtrend.xyaxis", color: .orange)
                    }
                }
            }
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
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Text(String(format: "%.1fh / %.1fh", current, target))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textMain)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.secondary)
                        .frame(height: 6)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(1.0, target > 0 ? current / target : 0)), height: 6)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
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
                            ForEach(viewModel.tasks) { task in
                                TaskRow(task: task, onToggle: {}, onStart: {}, onSpeak: { _ in })
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
                    
                    Button(action: {
                        isSubmitting = true
                        Task {
                            if let p = Double(price) {
                                try? await viewModel.createTask(title: title, description: description, price: p, assigneeId: selectedWorkerId)
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

struct AdminMoreView: View {
    @ObservedObject var viewModel: AdminViewModel
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List {
                    Section {
                        NavigationLink(destination: AdminTripsView(viewModel: viewModel)) {
                            Label("Trips", systemImage: "airplane")
                        }
                        NavigationLink(destination: AdminPayrollView(viewModel: viewModel)) {
                            Label("Payroll", systemImage: "dollarsign.circle.fill")
                        }
                        NavigationLink(destination: AdminAnnouncementsView(viewModel: viewModel)) {
                            Label("Announcements", systemImage: "megaphone.fill")
                        }
                    } header: {
                        Text("Management")
                    }
                    .listRowBackground(Theme.surface)
                    
                    Section {
                        Button(action: { sessionManager.logout() }) {
                            Label("Log Out", systemImage: "power")
                                .foregroundStyle(Theme.danger)
                        }
                    } header: {
                        Text("Account")
                    }
                    .listRowBackground(Theme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("More")
        }
    }
}

struct AdminTripsView: View {
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingAdd = false
    
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
                            Text(ann.tag.uppercased())
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
