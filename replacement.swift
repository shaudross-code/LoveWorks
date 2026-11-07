struct WorkerDashboardMainView: View {
    @ObservedObject var viewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingNotifications = false
    @State private var showingPicker = false
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    headerView
                    heroView
                    
                    if showingPicker {
                        ActivityPickerView(viewModel: viewModel) { showingPicker = false }
                            .padding(.horizontal)
                    }

                    deadlinesView
                    tasksView
                    
                    VStack(alignment: .leading, spacing: 16) {
                        WeeklyStripView(activity: viewModel.weeklyActivity)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(notifications: viewModel.notifications)
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            Button(action: { showingNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textMain)
                    
                    if viewModel.unreadNotificationsCount > 0 {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    private var heroView: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                Circle()
                    .fill(Theme.primary.opacity(0.1))
                    .frame(width: 420, height: 420)
                    .blur(radius: 60)
                    .offset(x: geo.size.width - 210, y: -210)
            }
            .allowsHitTesting(false)
            
            VStack(alignment: .leading, spacing: 24) {
                topRow
                tilesGrid
            }
            .padding(24)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1))
        .padding(.horizontal)
    }
    
    private var topRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if viewModel.activeEntries.isEmpty {
                        Text("READY TO START")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .tracking(1.5)
                    } else {
                        Text("CURRENTLY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .tracking(1.5)
                        
                        ForEach(viewModel.activeEntries, id: \.id) { entry in
                            let info = ActivityInfo.info(for: entry.activity)
                            HStack(spacing: 4) {
                                Image(systemName: info.icon)
                                    .font(.system(size: 10))
                                Text(info.label)
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(info.color.opacity(0.2))
                            .foregroundStyle(info.color)
                            .cornerRadius(100)
                        }
                    }
                }
                
                let viewTitle = viewModel.activeEntries.count > 1 ? "You're juggling \(viewModel.activeEntries.count) clocks." : (viewModel.activeEntries.count == 1 ? "You're on the clock." : "Punch in to begin.")
                Text(viewTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textMain)
            }
            Spacer()
            heroActionButtons
        }
    }
    
    private var heroActionButtons: some View {
        Group {
            if viewModel.activeEntries.isEmpty {
                Button(action: { showingPicker.toggle() }) {
                    VStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 32))
                            .padding(.bottom, 4)
                        Text("Clock In")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(width: 120, height: 120)
                    .background(Theme.primary)
                    .foregroundStyle(.black)
                    .clipShape(Circle())
                    .shadow(color: Theme.primary.opacity(0.3), radius: 20, y: 10)
                }
            } else {
                VStack(spacing: 8) {
                    let info = ActivityInfo.info(for: viewModel.activeEntries[0].activity)
                    ZStack {
                        Circle()
                            .stroke(info.bg, lineWidth: 4)
                            .frame(width: 120, height: 120)
                        VStack(spacing: 4) {
                            Image(systemName: info.icon)
                                .font(.system(size: 24))
                            Text(info.label.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .tracking(1)
                            Text(formatDuration(viewModel.liveSeconds))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(info.bg)
                    }
                    
                    HStack {
                        Button("Start Another") { showingPicker.toggle() }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.primary)
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                            
                        Button("Stop All") { Task { try? await viewModel.clockOut() } }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var tilesGrid: some View {
        let openCount = viewModel.tasks.filter { $0.status != "completed" }.count
        let earnings = viewModel.tasks.filter { $0.status == "completed" }.reduce(0) { $0 + (Double($1.price) ?? 0) }
        let wp = viewModel.tasks.filter { $0.status != "completed" && isDueThisWeek($0) }.reduce(0) { $0 + (Double($1.price) ?? 0) }
        let ot = viewModel.tasks.filter { $0.status != "completed" }.reduce(0) { $0 + (Double($1.price) ?? 0) }
        let hours = String(format: "%.2fh", viewModel.todayHours)
        let timer = viewModel.activeEntries.isEmpty ? "00:00:00" : formatDuration(viewModel.liveSeconds)
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTileV2(label: viewModel.activeEntries.count > 1 ? "Earliest timer" : "Shift timer", value: timer, icon: "timer")
            StatTileV2(label: "Today", value: hours, icon: "clock")
            StatTileV2(label: "Open tasks", value: "\(openCount)", icon: "checklist")
            StatTileV2(label: "Earned", value: String(format: "$%.2f", earnings), icon: "dollarsign.circle", accent: Theme.primary)
            StatTileV2(label: "This week value", value: String(format: "$%.2f", wp), icon: "chart.line.uptrend.xyaxis", accent: Theme.primary)
            StatTileV2(label: "All open value", value: String(format: "$%.2f", ot), icon: "briefcase")
        }
    }
    
    private var deadlinesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deadlines")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textMain)
                    Text("What needs to ship today and this week.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal)
            
            let overdue = viewModel.tasks.filter { $0.status != "completed" && isOverdue($0) }
            let dueToday = viewModel.tasks.filter { $0.status != "completed" && isDueToday($0) }
            let dueThisWeek = viewModel.tasks.filter { $0.status != "completed" && isDueThisWeek($0) && !isDueToday($0) }
            let anytime = viewModel.tasks.filter { $0.status != "completed" && $0.dueAt == nil }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DeadlineBucket(title: "Overdue", tasks: overdue, tone: .red, icon: "exclamationmark.triangle.fill")
                DeadlineBucket(title: "Due today", tasks: dueToday, tone: .yellow, icon: "calendar")
                DeadlineBucket(title: "Due this week", tasks: dueThisWeek, tone: .sky, icon: "calendar.badge.clock")
                DeadlineBucket(title: "Open · anytime", tasks: anytime, tone: .zinc, icon: "hourglass")
            }
            .padding(.horizontal)
        }
    }
    
    private var tasksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            let openList = viewModel.tasks.filter { $0.status != "completed" }
            let doneList = viewModel.tasks.filter { $0.status == "completed" }
            
            HStack(alignment: .bottom) {
                Text("Your tasks")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textMain)
                Spacer()
                Text("\(openList.count) open · \(doneList.count) done")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(0.5)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                if viewModel.tasks.isEmpty {
                    EmptyStateView(icon: "sparkles", title: "No tasks yet", message: "Your admin will assign them here.")
                        .padding(40)
                } else {
                    let merged = openList + doneList
                    ForEach(merged.indices, id: \.self) { i in
                        let task = merged[i]
                        TaskRow(task: task, onToggle: {
                            Task { try? await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "completed" ? "assigned" : "completed") }
                        }, onStart: {
                            Task { try? await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "in_progress" ? "assigned" : "in_progress") }
                        }, onSpeak: { speak($0) })
                        
                        if i < merged.count - 1 {
                            Divider().background(Theme.border)
                        }
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
            .padding(.horizontal)
        }
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
        return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    private func isDueToday(_ task: TaskItem) -> Bool {
        guard let due = task.dueAt else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: due) else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    private func isDueThisWeek(_ task: TaskItem) -> Bool {
        guard let due = task.dueAt else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: due) else { return false }
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: Calendar.current.startOfDay(for: Date())) else { return false }
        return date < weekEnd && !isOverdue(task)
    }
}

struct StatTileV2: View {
    let label: String
    let value: String
    let icon: String?
    let accent: Color?
    
    init(label: String, value: String, icon: String? = nil, accent: Color? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
        self.accent = accent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if let i = icon {
                    Image(systemName: i)
                        .font(.system(size: 10))
                }
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
            }
            .foregroundStyle(Theme.textMuted)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(accent ?? .white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1, opacity: 0.7))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
