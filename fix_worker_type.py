import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Replace Worker with User
text = text.replace("@State private var editingWorker: Worker? = nil", "@State private var editingWorker: User? = nil")
text = text.replace("struct EditWorkerModal: View {\n    let worker: Worker", "struct EditWorkerModal: View {\n    let worker: User")

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Replaced Worker with User")

