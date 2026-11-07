import re

with open("iLoveWorks/WorkerViewModel.swift", "r") as f:
    text = f.read()

# Replace the payload part
old_update = """    func updateTaskAlarm(taskId: String, alarmTime: String?) async throws {
        let payload: [String: String?] = ["userAlarm": alarmTime]
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: payload)
        await refresh()
    }"""
new_update = """    struct AlarmUpdateRequest: Encodable {
        let userAlarm: String?
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(userAlarm, forKey: .userAlarm)
        }
    }
    
    func updateTaskAlarm(taskId: String, alarmTime: String?) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: AlarmUpdateRequest(userAlarm: alarmTime))
        await refresh()
    }"""
text = text.replace(old_update, new_update)

with open("iLoveWorks/WorkerViewModel.swift", "w") as f:
    f.write(text)
print("Patched WorkerViewModel encode!")
