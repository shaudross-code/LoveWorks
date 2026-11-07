import re

with open("iLoveWorks/WorkerViewModel.swift", "r") as f:
    text = f.read()

# adding updateTaskAlarm string
update_status = """    func updateTaskStatus(taskId: String, status: String) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: ["status": status])
        await refresh()
    }"""
update_alarm = """    func updateTaskStatus(taskId: String, status: String) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: ["status": status])
        await refresh()
    }

    func updateTaskAlarm(taskId: String, alarmTime: String?) async throws {
        let payload: [String: String?] = ["userAlarm": alarmTime]
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: payload)
        await refresh()
    }"""
text = text.replace(update_status, update_alarm)

with open("iLoveWorks/WorkerViewModel.swift", "w") as f:
    f.write(text)
print("WorkerViewModel patched")
