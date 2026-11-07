import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# 1. Add EditTaskModal properties 
old_task_edit = """    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime: Date"""
new_task_edit = """    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime: Date
    @State private var frequency: String
    @State private var payoutSchedule: String"""
text = text.replace(old_task_edit, new_task_edit)

old_task_init = """_selectedWorkerId = State(initialValue: task.assigneeId)
        _setMandatoryAlarm = State(initialValue: task.adminAlarm != nil)"""
new_task_init = """_selectedWorkerId = State(initialValue: task.assigneeId)
        _frequency = State(initialValue: task.frequency ?? "once")
        _payoutSchedule = State(initialValue: task.payoutSchedule ?? "per_task")
        _setMandatoryAlarm = State(initialValue: task.adminAlarm != nil)"""
text = text.replace(old_task_init, new_task_init)

old_task_fields = """                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASSIGN TO WORKER")"""
new_task_fields = """                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FREQUENCY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.textMuted)
                                Picker("Frequency", selection: $frequency) {
                                    ForEach(["once", "daily", "weekly", "monthly"], id: \\.self) { f in Text(f.capitalized).tag(f) }
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
                                    ForEach(["per_task", "daily", "weekly", "monthly"], id: \\.self) { p in Text(p.replacingOccurrences(of: "_", with: " ").capitalized).tag(p) }
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
                            Text("ASSIGN TO WORKER")"""
text = text.replace(old_task_fields, new_task_fields)

old_task_submit = """            title: title.isEmpty ? nil : title,
            description: description,
            price: Double(price),
            assigneeId: selectedWorkerId.isEmpty ? nil : selectedWorkerId,
            frequency: nil,
            adminAlarm: alarmStr
        )"""
new_task_submit = """            title: title.isEmpty ? nil : title,
            description: description,
            price: Double(price),
            assigneeId: selectedWorkerId.isEmpty ? nil : selectedWorkerId,
            frequency: frequency,
            payoutSchedule: payoutSchedule,
            adminAlarm: alarmStr
        )"""
text = text.replace(old_task_submit, new_task_submit)

# 2. Add EditGoalModal properties
old_goal_edit = """    @State private var targetAmount = ""
    @State private var period: String
    @State private var isSubmitting = false"""
new_goal_edit = """    @State private var targetAmount = ""
    @State private var period: String
    @State private var ownerId: String
    @State private var productLink: String
    @State private var imageUrl: String
    @State private var isSubmitting = false"""
text = text.replace(old_goal_edit, new_goal_edit)

old_goal_init = """_targetAmount = State(initialValue: goal.targetAmount != nil ? String(goal.targetAmount!) : "")
        _period = State(initialValue: goal.period ?? "")"""
new_goal_init = """_targetAmount = State(initialValue: goal.targetAmount != nil ? String(goal.targetAmount!) : "")
        _period = State(initialValue: goal.period ?? "")
        _ownerId = State(initialValue: goal.ownerId)
        _productLink = State(initialValue: goal.productLink ?? "")
        _imageUrl = State(initialValue: goal.imageUrl ?? "")"""
text = text.replace(old_goal_init, new_goal_init)


old_goal_fields = """                        VStack(alignment: .leading, spacing: 8) {
                            Text("DUE DATE / NOTE")"""
new_goal_fields = """                        VStack(alignment: .leading, spacing: 8) {
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
                                    Text(ownerId.isEmpty ? "Select Worker..." : (viewModel.workers.first(where: { $0.id == ownerId })?.name ?? "Unknown"))
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
                            Text("DUE DATE / NOTE")"""
text = text.replace(old_goal_fields, new_goal_fields)

old_goal_submit = """        let req = AdminViewModel.GoalUpdateRequest(
            title: title.isEmpty ? nil : title,
            targetAmount: Double(targetAmount),
            period: period.isEmpty ? nil : period
        )"""
new_goal_submit = """        let req = AdminViewModel.GoalUpdateRequest(
            title: title.isEmpty ? nil : title,
            targetAmount: Double(targetAmount),
            period: period.isEmpty ? nil : period,
            ownerId: ownerId.isEmpty ? nil : ownerId,
            productLink: productLink.isEmpty ? nil : productLink,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl
        )"""
text = text.replace(old_goal_submit, new_goal_submit)

# 3. Add EditWorker properties to EditWorkerModal
old_edit_worker_init = """    @ObservedObject var viewModel: AdminViewModel
    @Environment(\\.presentationMode) var presentationMode
    @State private var isSubmitting = false"""
new_edit_worker_init = """    @ObservedObject var viewModel: AdminViewModel
    @Environment(\\.presentationMode) var presentationMode
    @State private var name: String
    @State private var email: String
    @State private var isSubmitting = false
    
    init(worker: User, viewModel: AdminViewModel) {
        self.worker = worker
        self.viewModel = viewModel
        self._name = State(initialValue: worker.name)
        self._email = State(initialValue: worker.email)
    }"""
text = text.replace(old_edit_worker_init, new_edit_worker_init)

old_edit_worker_fields = """                        Text(worker.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                            
                        Text(worker.email)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.bottom, 20)

                        Button(action: deleteWorker) {"""
new_edit_worker_fields = """                        VStack(alignment: .leading, spacing: 8) {
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
                                .padding(.bottom, 20)
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
                        
                        Button(action: deleteWorker) {"""
text = text.replace(old_edit_worker_fields, new_edit_worker_fields)


old_edit_worker_submit = """    private func deleteWorker() {"""
new_edit_worker_submit = """    private func saveChanges() {
        isSubmitting = true
        let req = AdminViewModel.WorkerUpdateRequest(
            name: name,
            email: email
        )
        Task {
            try? await viewModel.updateWorker(workerId: worker.id, req: req)
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteWorker() {"""
text = text.replace(old_edit_worker_submit, new_edit_worker_submit)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

