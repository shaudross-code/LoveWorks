import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

# Update TaskCreateRequest struct
old_struct = """        let dueDayOfWeek: Int?
        let dueTime: String?"""
new_struct = """        let dueDayOfWeek: Int?
        let dueTime: String?
        let adminAlarm: String?"""
text = text.replace(old_struct, new_struct)

old_encode = """            try c.encode(dueDayOfWeek, forKey: .dueDayOfWeek)
            try c.encode(dueTime, forKey: .dueTime)
        }"""
new_encode = """            try c.encode(dueDayOfWeek, forKey: .dueDayOfWeek)
            try c.encode(dueTime, forKey: .dueTime)
            try c.encode(adminAlarm, forKey: .adminAlarm)
        }"""
text = text.replace(old_encode, new_encode)

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)
print("Patched AdminViewModel!")
