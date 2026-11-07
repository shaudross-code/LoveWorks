import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Fix targetAmount
text = text.replace("String(format: \"%.2f\", goal.targetAmount)", "String(format: \"%.2f\", goal.targetAmount ?? 0.0)")

# Fix AdminViewModel dynamic access
# The error was `value of type 'AdminViewModel' has no dynamic member 'updateTask' using key path from root type 'AdminViewModel'`
# Oh, that happens when you miss `import SwiftUI` or something?
# No, it happens when there actually IS NO `updateTask` compiled!
# I need to verify that `updateTask` is correctly in `AdminViewModel`!
with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Fixed modally")
