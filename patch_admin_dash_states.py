import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add states for editing
state_str = """    @State private var selectedWorkerId = ""
    @State private var showingGoalModal = false
    @State private var showingTripModal = false"""
    
new_state_str = """    @State private var selectedWorkerId = ""
    @State private var showingGoalModal = false
    @State private var showingTripModal = false
    @State private var editingTask: TaskItem? = nil
    @State private var editingGoal: Goal? = nil
    @State private var editingTrip: Goal? = nil"""
text = text.replace(state_str, new_state_str)

# Find TaskRow
old_taskrow = "TaskRow(task: task, onToggle: {}, onStart: {}, onSpeak: { _ in })"
new_taskrow = """TaskRow(task: task, onToggle: {}, onStart: {}, onSpeak: { _ in })
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingTask = task }"""
text = text.replace(old_taskrow, new_taskrow)

# Find GoalCard and TripCard
old_goalcard = "GoalCard(goal: goal)"
new_goalcard = """GoalCard(goal: goal)
                                        .onTapGesture { editingGoal = goal }"""
text = text.replace(old_goalcard, new_goalcard)

old_tripcard = "TripCard(trip: trip)"
new_tripcard = """TripCard(trip: trip)
                                        .onTapGesture { editingTrip = trip }"""
text = text.replace(old_tripcard, new_tripcard)

# Add sheets at the end of AdminDashboardMainView
end_view = """        }
        .sheet(isPresented: $showingNewTask) {"""
        
sheets = """        }
        .sheet(item: $editingTask) { task in
            EditTaskModal(task: task, viewModel: viewModel)
        }
        .sheet(item: $editingGoal) { goal in
            EditGoalModal(goal: goal, isTrip: false, viewModel: viewModel)
        }
        .sheet(item: $editingTrip) { trip in
            EditGoalModal(goal: trip, isTrip: true, viewModel: viewModel)
        }
        .sheet(isPresented: $showingNewTask) {"""
text = text.replace(end_view, sheets)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Patched AdminDashboardView states")
