with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

old_task = """TaskRow(task: task, onToggle: {
                                        run { try await viewModel.updateTaskStatus(taskId: task.id, status: task.isCompleted ? "assigned" : "completed") }
                                    }, onStart: {
                                        run { try await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "in_progress" ? "assigned" : "in_progress") }
                                    }, onSpeak: { speak($0) })"""
new_task = """TaskRow(task: task, onToggle: {
                                        run { try await viewModel.updateTaskStatus(taskId: task.id, status: task.isCompleted ? "assigned" : "completed") }
                                    }, onStart: {
                                        run { try await viewModel.updateTaskStatus(taskId: task.id, status: task.status == "in_progress" ? "assigned" : "in_progress") }
                                    }, onSpeak: { speak($0) }, onSaveAlarm: { alarm in 
                                        run { try await viewModel.updateTaskAlarm(taskId: task.id, alarmTime: alarm) }
                                    })"""
text = text.replace(old_task, new_task)

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)
print("WorkerDashboardView patched")
