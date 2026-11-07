import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Replace the entire EditTaskModal
# It starts at: struct EditTaskModal: View {
# It ends at the end of the struct
old_task_regex = r"struct EditTaskModal: View \{.*?\n\}\n\nstruct EditGoalModal: View \{"

new_task_str = """struct EditTaskModal: View {
    let task: TaskItem
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var price: String
    @State private var selectedWorkerId: String
    @State private var adminAlarm: String?
    @State private var setMandatoryAlarm: Bool
    @State private var mandatoryAlarmTime: Date
    @State private var isSubmitting = false
    
    init(task: TaskItem, viewModel: AdminViewModel) {
        self.task = task
        self.viewModel = viewModel
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _price = State(initialValue: String(format: "%.2f", task.price))
        _selectedWorkerId = State(initialValue: task.assigneeId)
        
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
            frequency: nil,
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

struct EditGoalModal: View {"""

text = re.sub(old_task_regex, new_task_str, text, flags=re.DOTALL)

old_goal_regex = r"struct EditGoalModal: View \{.*?\}\n\}\n"
new_goal_str = """struct EditGoalModal: View {
    let goal: Goal
    let isTrip: Bool
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var targetAmount: String
    @State private var period: String
    @State private var isSubmitting = false
    
    init(goal: Goal, isTrip: Bool, viewModel: AdminViewModel) {
        self.goal = goal
        self.isTrip = isTrip
        self.viewModel = viewModel
        _title = State(initialValue: goal.title)
        _targetAmount = State(initialValue: String(format: "%.2f", goal.targetAmount ?? 0.0))
        _period = State(initialValue: goal.period ?? "")
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
            period: period.isEmpty ? nil : period
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
"""
text = re.sub(old_goal_regex, new_goal_str, text, flags=re.DOTALL)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Updated edit views structure thoroughly.")
