//
//  TaskFormView.swift
//  iLoveWorks
//
//  Admin: create or edit a task, including an alarm that rings for the assigned worker.
//

import SwiftUI

struct TaskFormView: View {
    @ObservedObject var viewModel: AdminViewModel
    let existing: TaskItem?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var price: String
    @State private var workerId: String
    @State private var frequency: String
    @State private var dueDay: Int
    @State private var hasDueTime: Bool
    @State private var dueTime: Date
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var alarmMode: String
    @State private var alarmMinutes: Int
    @State private var alarmDate: Date
    @State private var alarmDays: [Int]
    @State private var saving = false
    @State private var error: String?

    static let minuteOptions = [5, 10, 15, 30, 45, 60, 90, 120, 180, 1440]
    private static let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private static let frequencies = [("once", "One-time"), ("daily", "Daily"), ("weekly", "Weekly"), ("monthly", "Monthly")]

    init(viewModel: AdminViewModel, existing: TaskItem? = nil) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _details = State(initialValue: existing?.description ?? "")
        _price = State(initialValue: existing.map { String(format: "%.2f", $0.price) } ?? "")
        _workerId = State(initialValue: existing?.assigneeId ?? "")
        _frequency = State(initialValue: existing?.frequency ?? "once")
        _dueDay = State(initialValue: existing?.dueDayOfWeek ?? -1)
        _hasDueTime = State(initialValue: existing?.dueTime != nil)
        _dueTime = State(initialValue: Self.timeToday(existing?.dueTime ?? "17:00"))
        _hasDeadline = State(initialValue: existing?.dueAt != nil)
        _deadline = State(initialValue: APIDate.parse(existing?.dueAt) ?? Date())
        let alarm = existing?.alarm
        _alarmMode = State(initialValue: alarm?.mode ?? "none")
        _alarmMinutes = State(initialValue: alarm?.minutes ?? 30)
        _alarmDays = State(initialValue: alarm?.repeatDays ?? [])
        let alarmStart = alarm?.timeOfDay.map { Self.timeToday($0) } ?? APIDate.parse(alarm?.fireAt) ?? Date().addingTimeInterval(3600)
        _alarmDate = State(initialValue: alarmStart)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task name", text: $title)
                    TextField("What needs to be done?", text: $details, axis: .vertical)
                    TextField("Price (USD)", text: $price)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Picker("Assignee", selection: $workerId) {
                        Text("Pick a worker").tag("")
                        ForEach(viewModel.workers) { w in Text(w.name).tag(w.id) }
                    }
                }

                Section("Schedule") {
                    Picker("Repeats", selection: $frequency) {
                        ForEach(Self.frequencies, id: \.0) { f in Text(f.1).tag(f.0) }
                    }
                    if frequency == "weekly" || frequency == "once" {
                        Picker("Day", selection: $dueDay) {
                            Text("No specific day").tag(-1)
                            ForEach(0..<7, id: \.self) { d in Text(Self.days[d]).tag(d) }
                        }
                    }
                    if frequency == "once" {
                        Toggle("Deadline date", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Date", selection: $deadline, displayedComponents: [.date])
                        }
                    }
                    Toggle("Due time", isOn: $hasDueTime)
                    if hasDueTime {
                        DatePicker("Due by", selection: $dueTime, displayedComponents: [.hourAndMinute])
                    }
                }

                Section {
                    Picker("Alarm", selection: $alarmMode) {
                        Text("None").tag("none")
                        Text("Before due").tag("before")
                        Text("Pick time").tag("exact")
                    }
                    .pickerStyle(.segmented)
                    if alarmMode == "before" {
                        Picker("Rings", selection: $alarmMinutes) {
                            ForEach(Self.minuteOptions, id: \.self) { m in Text("\(Self.minutesLabel(m)) before").tag(m) }
                        }
                        if !hasDueTime {
                            Text("Turn on Due time so the alarm knows when to ring.")
                                .font(.footnote)
                                .foregroundStyle(Theme.primary)
                        }
                    }
                    if alarmMode == "exact" {
                        RepeatDaysPicker(days: $alarmDays)
                        if alarmDays.isEmpty {
                            DatePicker("Rings at", selection: $alarmDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        } else {
                            DatePicker("Rings at", selection: $alarmDate, displayedComponents: [.hourAndMinute])
                        }
                    }
                } header: {
                    Text("Alarm for the worker")
                } footer: {
                    Text(alarmMode == "none" ? "No alarm." : "Rings on their phone and web app, even with iLoveWorks closed. Removed when the task is done.")
                }

                if let error {
                    Section { Text(error).foregroundStyle(Theme.danger) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(existing == nil ? "New task" : "Edit task")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : (existing == nil ? "Assign" : "Save")) { save() }
                        .disabled(saving || title.trimmingCharacters(in: .whitespaces).isEmpty || workerId.isEmpty)
                }
            }
        }
    }

    private var alarmConfig: TaskAlarmConfig? {
        switch alarmMode {
        case "before":
            return TaskAlarmConfig(mode: "before", minutes: alarmMinutes)
        case "exact":
            if alarmDays.isEmpty {
                return TaskAlarmConfig(mode: "exact", fireAt: ISO8601DateFormatter().string(from: alarmDate))
            }
            return TaskAlarmConfig(mode: "exact", repeatDays: alarmDays.sorted(), timeOfDay: Self.hhmm(alarmDate), tz: TimeZone.current.identifier)
        default:
            return nil
        }
    }

    private func save() {
        guard let p = Double(price.replacingOccurrences(of: "$", with: "")), p >= 0 else {
            error = "Enter a price (0 or more)."
            return
        }
        let dayFmt = DateFormatter()
        dayFmt.calendar = Calendar(identifier: .gregorian)
        dayFmt.dateFormat = "yyyy-MM-dd"
        let req = AdminViewModel.TaskSaveRequest(
            title: title.trimmingCharacters(in: .whitespaces),
            description: details,
            price: p,
            assigneeId: workerId,
            frequency: frequency,
            dueDayOfWeek: (frequency == "weekly" || frequency == "once") && dueDay >= 0 ? dueDay : nil,
            dueTime: hasDueTime ? Self.hhmm(dueTime) : nil,
            dueAt: frequency == "once" && hasDeadline ? dayFmt.string(from: deadline) : nil,
            alarm: alarmConfig,
            forUpdate: existing != nil
        )
        saving = true
        error = nil
        Task {
            do {
                if let existing {
                    try await viewModel.updateTask(id: existing.id, req)
                } else {
                    try await viewModel.createTask(req)
                }
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            saving = false
        }
    }

    static func minutesLabel(_ m: Int) -> String {
        if m >= 1440 { return "1 day" }
        if m >= 60 { return m % 60 == 0 ? "\(m / 60) hr" : String(format: "%.1f hr", Double(m) / 60) }
        return "\(m) min"
    }

    static func alarmLabel(_ a: TaskAlarmConfig) -> String {
        if a.mode == "before", let m = a.minutes { return "\(minutesLabel(m)) before due" }
        if let days = a.repeatDays, !days.isEmpty, let t = a.timeOfDay {
            return "\(AlarmItem.repeatSummary(days)) \(timeToday(t).formatted(date: .omitted, time: .shortened))"
        }
        return APIDate.parse(a.fireAt)?.formatted(date: .abbreviated, time: .shortened) ?? "Alarm"
    }

    static func timeToday(_ hhmm: String) -> Date {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return Date() }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date()) ?? Date()
    }

    static func hhmm(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}
