import re

with open("iLoveWorks/WorkerViewModel.swift", "r") as f:
    text = f.read()

# Modify updateTaskAlarm to also schedule the local alarm

old_alarm = """    func updateTaskAlarm(taskId: String, alarmTime: String?) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: AlarmUpdateRequest(userAlarm: alarmTime))
        await refresh()
    }"""
new_alarm = """    func updateTaskAlarm(taskId: String, alarmTime: String?, taskTitle: String) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: AlarmUpdateRequest(userAlarm: alarmTime))
        PushManager.shared.scheduleAlarm(id: taskId, title: "Task Alarm", body: taskTitle, timeString: alarmTime)
        await refresh()
    }"""

text = text.replace(old_alarm, new_alarm)

# Now, we also want to schedule all alarms when data is loaded/refreshed, including admin alarms.
refresh_hook = """        if let v = await active { activeEntries = v }
        if let v = resTasks { tasks = v }"""
refresh_hook_new = """        if let v = await active { activeEntries = v }
        if let v = resTasks {
            tasks = v
            for task in v {
                let alarm = task.adminAlarm ?? task.userAlarm
                PushManager.shared.scheduleAlarm(id: task.id, title: "Task Alarm", body: task.title, timeString: alarm)
            }
        }"""
text = text.replace(refresh_hook, refresh_hook_new)

with open("iLoveWorks/WorkerViewModel.swift", "w") as f:
    f.write(text)
print("WorkerViewModel patched")
