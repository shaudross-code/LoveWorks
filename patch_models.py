import re

with open("iLoveWorks/Models.swift", "r") as f:
    text = f.read()

text = text.replace("let dueTime: String?", "let dueTime: String?\n    let adminAlarm: String?\n    let userAlarm: String?")

with open("iLoveWorks/Models.swift", "w") as f:
    f.write(text)
print("Updated Models.swift!")
