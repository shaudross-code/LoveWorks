import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# We need to replace:
# ForEach(viewModel.tasks) { task in
# with:
# ForEach(viewModel.tasks.sorted { !$0.isCompleted && $1.isCompleted }) { task in

pattern = re.compile(r"ForEach\(viewModel\.tasks\) \{ task in")

if not pattern.search(text):
    print("Could not find pattern")
else:
    new_text = pattern.sub(r"ForEach(viewModel.tasks.sorted { !$0.isCompleted && $1.isCompleted }) { task in", text)
    with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
        f.write(new_text)
    print("Patched sort!")
