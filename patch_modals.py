import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# ============ PATCH EDIT TASK MODAL ============
# Add frequency and payoutSchedule state
if "@State private var frequency: String" not in text:
    old = "@State private var mandatoryAlarmTime: Date"
    new = "@State private var mandatoryAlarmTime: Date\n    @State private var frequency: String\n    @State private var payoutSchedule: String"
    text = text.replace("    @State private var isSubmitting = false\n    \n    var body: some View {\n        NavigationView {\n            ZStack {\n                Theme.background.ignoresSafeArea()\n                \n                ScrollView {\n                    VStack(spacing: 24) {\n                        if let urlString = worker.avatarUrl", new + "\n    \n    var body: some View {\n        NavigationView {\n            ZStack {\n                Theme.background.ignoresSafeArea()\n                \n                ScrollView {\n                    VStack(spacing: 24) {\n                        if let urlString = worker.avatarUrl")
    
    old_init = "_selectedWorkerId = State(initialValue: task.assigneeId)"
    new_init = "_selectedWorkerId = State(initialValue: task.assigneeId)\n        _frequency = State(initialValue: task.frequency ?? \"once\")\n        _payoutSchedule = State(initialValue: task.payoutSchedule ?? \"per_task\")"
    text = text.replace(old_init, new_init)

    old_view = """                        VStack(alignment: .leading, spacing: 8) {
                            Text("ASSIGN TO WORKER")"""
    new_view = """                        HStack(spacing: 16) {
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
    text = text.replace(old_view, new_view)
    
    old_req = """        let req = AdminViewModel.TaskUpdateRequest(
            title: title.isEmpty ? nil : title,
            description: description,
            price: Double(price),
            assigneeId: selectedWorkerId.isEmpty ? nil : selectedWorkerId,
            frequency: nil,
            adminAlarm: alarmStr
        )"""
    new_req = """        let req = AdminViewModel.TaskUpdateRequest(
            title: title.isEmpty ? nil : title,
            description: description,
            price: Double(price),
            assigneeId: selectedWorkerId.isEmpty ? nil : selectedWorkerId,
            frequency: frequency,
            payoutSchedule: payoutSchedule,
            adminAlarm: alarmStr
        )"""
    text = text.replace(old_req, new_req)

# ============ PATCH EDIT GOAL MODAL ============
if "@State private var ownerId: String" not in text:
    old = "@State private var period: String\n    @State private var isSubmitting = false"
    new = "@State private var period: String\n    @State private var ownerId: String\n    @State private var productLink: String\n    @State private var imageUrl: String\n    @State private var isSubmitting = false"
    text = text.replace("    @State private var isSubmitting = false\n    \n    var body: some View {\n        NavigationView {\n            ZStack {\n                Theme.background.ignoresSafeArea()\n                \n                ScrollView {\n                    VStack(spacing: 24) {\n                        if let urlString = worker.avatarUrl", new + "\n    \n    var body: some View {\n        NavigationView {\n            ZStack {\n                Theme.background.ignoresSafeArea()\n                \n                ScrollView {\n                    VStack(spacing: 24) {\n                        if let urlString = worker.avatarUrl")
    
    old_init = "_period = State(initialValue: goal.period ?? \"\")\n    }"
    new_init = "_period = State(initialValue: goal.period ?? \"\")\n        _ownerId = State(initialValue: goal.ownerId)\n        _productLink = State(initialValue: goal.productLink ?? \"\")\n        _imageUrl = State(initialValue: goal.imageUrl ?? \"\")\n    }"
    text = text.replace(old_init, new_init)

    old_view = """                        VStack(alignment: .leading, spacing: 8) {
                            Text("DUE DATE / NOTE")"""
    
    new_view = """                        VStack(alignment: .leading, spacing: 8) {
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
                            Text("DUE DATE / NOTE")"""
    text = text.replace(old_view, new_view)

    old_req = """        let req = AdminViewModel.GoalUpdateRequest(
            title: title.isEmpty ? nil : title,
            targetAmount: Double(targetAmount),
            period: period.isEmpty ? nil : period
        )"""
    new_req = """        let req = AdminViewModel.GoalUpdateRequest(
            title: title.isEmpty ? nil : title,
            targetAmount: Double(targetAmount),
            period: period.isEmpty ? nil : period,
            ownerId: ownerId.isEmpty ? nil : ownerId,
            productLink: productLink.isEmpty ? nil : productLink,
            imageUrl: imageUrl.isEmpty ? nil : imageUrl
        )"""
    text = text.replace(old_req, new_req)

# ============ PATCH EDIT WORKER MODAL ============
if "@State private var name: String" not in text:
    old = "@State private var isSubmitting = false"
    new = "@State private var name: String\n    @State private var email: String\n    @State private var isSubmitting = false\n    \n    init(worker: User, viewModel: AdminViewModel) {\n        self.worker = worker\n        self.viewModel = viewModel\n        _name = State(initialValue: worker.name)\n        _email = State(initialValue: worker.email)\n    }"
    text = text.replace("    @State private var isSubmitting = false\n    \n    var body: some View {\n        NavigationView {\n            ZStack {\n                Theme.background.ignoresSafeArea()\n                \n                ScrollView {\n                    VStack(spacing: 24) {\n                        if let urlString = worker.avatarUrl", new + "\n    \n    var body: some View {\n        NavigationView {\n            ZStack {\n                Theme.background.ignoresSafeArea()\n                \n                ScrollView {\n                    VStack(spacing: 24) {\n                        if let urlString = worker.avatarUrl")
    
    old_view = """                        Text(worker.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.textMain)
                            
                        Text(worker.email)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.bottom, 20)

                        Button(action: deleteWorker) {"""
    
    new_view = """                        VStack(alignment: .leading, spacing: 8) {
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
    text = text.replace(old_view, new_view)

    add_save = """    private func saveChanges() {
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
    
    private func deleteWorker"""
    text = text.replace("    private func deleteWorker", add_save)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Forms patched successfully.")
