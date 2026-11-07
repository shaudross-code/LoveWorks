import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    content = f.read()

# Fix inconsistencies access
content = content.replace("status.inconsistencies.totalIssues", "(status.inconsistencies?.totalIssues ?? 0)")
content = content.replace("status.inconsistencies.streakBroken", "status.inconsistencies?.streakBroken == true")
content = content.replace("status.inconsistencies.scheduleMissed", "status.inconsistencies?.scheduleMissed == true")
content = content.replace("status.inconsistencies.performanceDrop", "status.inconsistencies?.performanceDrop == true")

# Fix createTask
content = content.replace(
    "try? await viewModel.createTask(title: title, description: description, price: p, assigneeId: selectedWorkerId)",
    "try? await viewModel.createTask(AdminViewModel.TaskCreateRequest(title: title, description: description, price: p, assigneeId: selectedWorkerId, frequency: \"one-off\"))"
)

# Fix uppercased on optional
content = content.replace("Text(ann.tag.uppercased())", "Text((ann.tag ?? \"\").uppercased())")

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(content)
