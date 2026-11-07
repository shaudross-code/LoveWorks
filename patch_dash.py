import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    content = f.read()

main_view_start = content.find("struct WorkerDashboardMainView: View {")
activity_picker_start = content.find("struct ActivityPickerView: View {")

if main_view_start == -1 or activity_picker_start == -1:
    print("Could not find blocks")
    exit(1)

new_main_view = """struct WorkerDashboardMainView: View {
    @ObservedObject var viewModel: WorkerViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingNotifications = false
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    
                    // --- HERO SECTION (Web Parity) ---
                    ZStack {
                        // Blurred background orb
                        GeometryReader { geo in
                            Circle()
                                .fill(Theme.primary.opacity(0.1))
                                .frame(width: 420, height: 420)
                                .blur(radius: 60)
                                .offset(x: geo.size.width - 210, y: -210) // top-right
                        }
                        .allowsHitTesting(false)
                        
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // "Currently" / "Ready" Row
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
                                        
                                        ForEach(viewModel.activeEntries, id: \\.id) { entry in
                                            let info = ActivityInfo.info(for: entry.activity)
                                            HStack(spacing: 4) {
                                                Image(systemName: info.icon)
                                                    .font(.system(size: 10))
                                                Text(info.label)
                                                    .font(.system(size: 10, weight: .semibold))
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(info.bg.opacity(0.2))
                                            .foregroundStyle(info.bg)
                                            .cornerRadius(100)
                                        }
                                    }
                                }
                                
                                // Dynamic Hero Title
                                let viewTitle: String = {
                                    if viewModel.activeEntries.count > 1 {
                                        return "You're juggling \\(viewModel.activeEntries.count) clocks."
                                    } else if viewModel.activeEntries.count == 1 {
                                        return "You're on the clock."
                                    }
                                    return "Punch in to begin."
                                }()
                                
                                Text(viewTitle)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textMain)
                            }
                            
                            // 3x Grid Tiles
                            let openCount = viewModel.tasks.filter { $0.status != "completed" }.count
                            let hours = String(format: "%.2fh", viewModel.todayHours)
                            let timer = viewModel.activeEntries.isEmpty ? "00:00:00" : formatDuration(viewModel.liveSeconds)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatTile(label: "Shift timer", value: timer, icon: "timer")
                                StatTile(label: "Today", value: hours, icon: "clock")
                                StatTile(label: "Open tasks", value: "\\(openCount)", icon: "checklist")
                            }
                            
                            // Active Clocks Rows or Activity Picker
                            if viewModel.activeEntries.isEmpty {
                                Text("Start a new clock")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textMain)
                                    .padding(.top, 8)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(ActivityInfo.all) { info in
                                        Button(action: { Task { try? await viewModel.clockIn(activity: info.id) } }) {
                                            VStack(spacing: 8) {
                                                Circle()
                                                    .fill(info.bg)
                                                    .frame(width: 48, height: 48)
                                                    .overlay(Image(systemName: info.icon).foregroundStyle(info.color))
                                                Text(info.label)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(Theme.textMain)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Theme.surfaceHover)
                                            .cornerRadius(16)
                                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.secondary, lineWidth: 1))
                                        }
                                        .disabled(viewModel.isLoading)
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.activeEntries, id: \\.id) { entry in
                                        let info = ActivityInfo.info(for: entry.activity)
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(info.bg)
                                                .frame(width: 40, height: 40)
                                                .overlay(Image(systemName: info.icon).foregroundStyle(.white))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(info.label)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.white)
                                                Text(formatDuration(viewModel.liveSeconds))
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundStyle(Theme.textMuted)
                                            }
                                            Spacer()
                                            
                                            Button(action: { Task { try? await viewModel.clockOut(entryId: entry.id) } }) {
                                                Text("Stop")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.red.opacity(0.15))
                                                    .foregroundStyle(Color.red.opacity(0.8))
                                                    .cornerRadius(100)
                                            }
                                        }
                                        .padding(12)
                                        .background(Theme.surfaceHover)
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.secondary, lineWidth: 1))
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1))
                    .padding(.horizontal)
                    .padding(.top, 16) // Spacing from nav bar

                    // --- DEADLINES SECTION ---
                    VStack(alignment: .leading, spacing: 16) {
                        let overdue = viewModel.tasks.filter { $0.status != "completed" && isOverdue($0) }
                        let dueToday = viewModel.tasks.filter { $0.status != "completed" && isDueToday($0) }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DeadlineBucket(title: "Overdue", tasks: overdue, tone: .red, icon: "exclamationmark.triangle.fill")
                            DeadlineBucket(title: "Due Today", tasks: dueToday, tone: .yellow, icon: "calendar")
                        }
                        .padding(.horizontal)
                    }

                    // --- OPEN TASKS SECTION ---
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Your tasks")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textMain)
                            Spacer()
                            Text("\\(viewModel.tasks.filter { $0.status != "completed" }.count) open")
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
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct StatTile: View {
    let label: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
            }
            .foregroundStyle(Theme.textMuted)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceHover)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.secondary, lineWidth: 1))
    }
}

"""

new_content = content[:main_view_start] + new_main_view + content[activity_picker_start:]

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(new_content)

print("Patched WorkerDashboardMainView!")
