import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

# I want to conditionally show the `Button(action: { showingAlarm = true })`
# only if `onSaveAlarm != nil`.

old_btn = """                    } else {
                         Button(action: { showingAlarm = true }) {
                             MetadataChip(label: task.userAlarm ?? "Set Alarm", icon: task.userAlarm != nil ? "bell.fill" : "bell", color: task.userAlarm != nil ? .orange : Theme.textMuted)
                         }
                    }"""
new_btn = """                    } else {
                         if onSaveAlarm != nil {
                             Button(action: { showingAlarm = true }) {
                                 MetadataChip(label: task.userAlarm ?? "Set Alarm", icon: task.userAlarm != nil ? "bell.fill" : "bell", color: task.userAlarm != nil ? .orange : Theme.textMuted)
                             }
                         }
                    }"""

text = text.replace(old_btn, new_btn)

with open("iLoveWorks/CommonUI.swift", "w") as f:
    f.write(text)
print("Patched TaskRow Admin fix!")
