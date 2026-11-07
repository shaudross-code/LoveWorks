import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add states
state_old = "    @State private var isSubmitting = false"
state_new = """    @State private var isSubmitting = false
    @State private var setMandatoryAlarm = false
    @State private var mandatoryAlarmTime = Date()"""
text = text.replace(state_old, state_new)

# Add UI inside VStack(spacing: 24)
# Between Assignee and Assign Task button.
# Let's target the end of HStack(spacing: 16)
end_hstack_old = """                        }
                    }
                    
                    Button(action: {"""
end_hstack_new = """                        }
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
                    
                    Button(action: {"""
text = text.replace(end_hstack_old, end_hstack_new)

# Update createTask call
call_old = "try? await viewModel.createTask(AdminViewModel.TaskCreateRequest(title: title, description: description, price: p, assigneeId: selectedWorkerId, frequency: \"one-off\", dueDayOfWeek: nil, dueTime: nil))"
call_new = """
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                let alarmStr = setMandatoryAlarm ? formatter.string(from: mandatoryAlarmTime) : nil
                                try? await viewModel.createTask(AdminViewModel.TaskCreateRequest(title: title, description: description, price: p, assigneeId: selectedWorkerId, frequency: "one-off", dueDayOfWeek: nil, dueTime: nil, adminAlarm: alarmStr))"""
text = text.replace(call_old, call_new)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Patched modal!")
