import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# AdminTasksView
text = text.replace(
    "@State private var showingAddTask = false",
    "@State private var showingAddTask = false\n    @State private var editingTask: TaskItem? = nil"
)
text = text.replace(
    ".sheet(isPresented: $showingAddTask) {",
    ".sheet(item: $editingTask) { task in\n                EditTaskModal(task: task, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAddTask) {"
)

# AdminGoalsView
text = text.replace(
    "@State private var showingAddGoal = false",
    "@State private var showingAddGoal = false\n    @State private var editingGoal: Goal? = nil"
)
old_goalcard = "GoalCard(goal: goal)"
new_goalcard = """GoalCard(goal: goal)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingGoal = goal }"""
if old_goalcard in text:
    text = text.replace(old_goalcard, new_goalcard)
else:
    print("GoalCard already patched?")

text = text.replace(
    ".sheet(isPresented: $showingAddGoal) {",
    ".sheet(item: $editingGoal) { goal in\n                EditGoalModal(goal: goal, isTrip: false, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAddGoal) {"
)

# AdminTripsView
text = text.replace(
    "struct AdminTripsView: View {\n    @ObservedObject var viewModel: AdminViewModel\n    @State private var showingAdd = false",
    "struct AdminTripsView: View {\n    @ObservedObject var viewModel: AdminViewModel\n    @State private var showingAdd = false\n    @State private var editingTrip: Goal? = nil"
)
old_tripcard = "TripCard(trip: trip)"
new_tripcard = """TripCard(trip: trip)
                                        .contentShape(Rectangle())
                                        .onTapGesture { editingTrip = trip }"""
if old_tripcard in text:
    text = text.replace(old_tripcard, new_tripcard)
else:
    print("TripCard already patched?")

text = text.replace(
    ".sheet(isPresented: $showingAdd) {",
    ".sheet(item: $editingTrip) { trip in\n                EditGoalModal(goal: trip, isTrip: true, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAdd) {"
)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Patched AdminTasksView, AdminGoalsView, AdminTripsView!")
