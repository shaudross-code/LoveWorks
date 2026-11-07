import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

pattern = re.compile(r"ForEach\(viewModel\.tasks\) \{ task in")

if not pattern.search(text):
    print("Could not find pattern in admin view")
else:
    new_text = pattern.sub(r"ForEach(viewModel.tasks.sorted { !$0.isCompleted && $1.isCompleted }) { task in", text)
    with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
        f.write(new_text)
    print("Patched admin sort!")
