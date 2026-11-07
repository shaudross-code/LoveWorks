import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# Modify call in view
old_call = "run { try await viewModel.updateTaskAlarm(taskId: task.id, alarmTime: alarm) }"
new_call = "run { try await viewModel.updateTaskAlarm(taskId: task.id, alarmTime: alarm, taskTitle: task.title) }"
text = text.replace(old_call, new_call)

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)
print("WorkerDashboardView call updated")
