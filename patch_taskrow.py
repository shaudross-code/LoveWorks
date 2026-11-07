import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

# Update signature
old_sig = """struct TaskRow: View {
    let task: TaskItem
    var showAssignee = false
    let onToggle: () -> Void
    let onStart: () -> Void
    let onSpeak: (String) -> Void

    var body: some View {"""

new_sig = """struct TaskRow: View {
    let task: TaskItem
    var showAssignee = false
    let onToggle: () -> Void
    let onStart: () -> Void
    let onSpeak: (String) -> Void
    var onSaveAlarm: ((String?) -> Void)? = nil

    @State private var showingAlarm = false
    @State private var draftAlarmTime = Date()

    var body: some View {"""
text = text.replace(old_sig, new_sig)

# Add Alarm chips to the tags flow layout
old_chips = """                    if showAssignee, let name = task.assigneeName {
                        MetadataChip(label: name, icon: "person.fill", color: Theme.textMuted)
                    }
                }"""

new_chips = """                    if showAssignee, let name = task.assigneeName {
                        MetadataChip(label: name, icon: "person.fill", color: Theme.textMuted)
                    }
                    if let adminAlarm = task.adminAlarm {
                         MetadataChip(label: adminAlarm + " (Mandatory)", icon: "bell.fill", color: Theme.danger)
                    } else {
                         Button(action: { showingAlarm = true }) {
                             MetadataChip(label: task.userAlarm ?? "Set Alarm", icon: task.userAlarm != nil ? "bell.fill" : "bell", color: task.userAlarm != nil ? .orange : Theme.textMuted)
                         }
                    }
                }
                .sheet(isPresented: $showingAlarm) {
                    NavigationView {
                        VStack(spacing: 24) {
                            DatePicker("Select Alarm Time", selection: $draftAlarmTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .padding()
                            
                            Button(action: {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let str = formatter.string(from: draftAlarmTime)
                                onSaveAlarm?(str)
                                showingAlarm = false
                            }) {
                                Text("Save Alarm")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.loveGradient)
                                    .foregroundStyle(.white)
                                    .cornerRadius(100)
                            }
                            .padding(.horizontal, 24)
                            
                            if task.userAlarm != nil {
                                Button("Remove Alarm") {
                                    onSaveAlarm?(nil)
                                    showingAlarm = false
                                }
                                .foregroundStyle(Theme.danger)
                                .padding(.top, 8)
                            }
                            Spacer()
                        }
                        .navigationTitle("Task Alarm")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showingAlarm = false }
                            }
                        }
                    }
                    .presentationDetents([.fraction(0.6)])
                }"""

text = text.replace(old_chips, new_chips)

with open("iLoveWorks/CommonUI.swift", "w") as f:
    f.write(text)
print("Patched TaskRow!")
