import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Fix AdminEssentialsView sheet
text = re.sub(
    r"\.sheet\(item: \$editingTrip\) \{\s*trip in\s*EditGoalModal\(goal: trip, isTrip: true, viewModel: viewModel\)\s*\}\s*\.sheet\(isPresented: \$showingAdd\) \{",
    ".sheet(isPresented: $showingAdd) {",
    text
)
# Ensure any other leftover .sheet(item: $editingTrip) where $editingTrip doesn't belong is gone!
# Wait, I just want to keep it in `AdminTripsView`.
# Let's count where `.sheet(item: $editingTrip)` is.
# In `AdminTripsView`, we added `@State private var editingTrip: Goal? = nil`.
# So let's check where it is missing.

# Fix `goal.period`
text = text.replace("_period = State(initialValue: goal.period)", '_period = State(initialValue: goal.period ?? "")')

# Fix warning left side of nil coalescing operator
text = text.replace("_selectedWorkerId = State(initialValue: task.assigneeId ?? \"\")", '_selectedWorkerId = State(initialValue: task.assigneeId)')

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Fixed sheets and period finally")
