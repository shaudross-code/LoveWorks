import re

# Fix AdminViewModel CodingKeys
with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()
text = text.replace("case title, description, price, assigneeId, frequency, dueDayOfWeek, dueTime", "case title, description, price, assigneeId, frequency, dueDayOfWeek, dueTime, adminAlarm")
with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)
    
# Fix WorkerViewModel AlarmUpdateRequest
with open("iLoveWorks/WorkerViewModel.swift", "r") as f:
    text = f.read()

old_alarm_req = """    struct AlarmUpdateRequest: Encodable {
        let userAlarm: String?
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(userAlarm, forKey: .userAlarm)
        }
    }"""
new_alarm_req = """    struct AlarmUpdateRequest: Encodable {
        let userAlarm: String?
        enum CodingKeys: String, CodingKey {
            case userAlarm
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(userAlarm, forKey: .userAlarm)
        }
    }"""
text = text.replace(old_alarm_req, new_alarm_req)
with open("iLoveWorks/WorkerViewModel.swift", "w") as f:
    f.write(text)

