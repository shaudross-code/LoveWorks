import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# AdminEssentialsView - fix
# find struct AdminEssentialsView: View { up to .sheet(item: $editingTrip)
match = re.search(r"struct AdminEssentialsView: View \{.*?\.sheet\(item: \$editingTrip\) \{\s*EditGoalModal\(goal: trip, isTrip: true, viewModel: viewModel\)\s*\}\s*\.sheet\(isPresented: \$showingAdd\) \{", text, re.DOTALL)
if match:
    s = match.group(0).replace(".sheet(item: $editingTrip) {\n                EditGoalModal(goal: trip, isTrip: true, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAdd) {", ".sheet(isPresented: $showingAdd) {")
    text = text.replace(match.group(0), s)

# AdminAnnouncementsView - fix? It doesn't use showingAdd, it uses showingAdd
match2 = re.search(r"struct AdminAnnouncementsView: View \{.*?\.sheet\(item: \$editingTrip\) \{\s*EditGoalModal\(goal: trip, isTrip: true, viewModel: viewModel\)\s*\}\s*\.sheet\(isPresented: \$showingAdd\) \{", text, re.DOTALL)
if match2:
    s = match2.group(0).replace(".sheet(item: $editingTrip) {\n                EditGoalModal(goal: trip, isTrip: true, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAdd) {", ".sheet(isPresented: $showingAdd) {")
    text = text.replace(match2.group(0), s)
    
# Let's just fix it globally by regex except for AdminTripsView
def remove_bad_sheets(m):
    return m.group(0).replace(".sheet(item: $editingTrip) {\n                EditGoalModal(goal: trip, isTrip: true, viewModel: viewModel)\n            }\n            .sheet(isPresented: $showingAdd) {", ".sheet(isPresented: $showingAdd) {")

text = re.sub(r"struct AdminEssentialsView: View \{.*?\.sheet\(item: \$editingTrip\) \{\s*EditGoalModal.*?\.sheet\(isPresented: \$showingAdd\) \{", remove_bad_sheets, text, flags=re.DOTALL)
text = re.sub(r"struct AdminAnnouncementsView: View \{.*?\.sheet\(item: \$editingTrip\) \{\s*EditGoalModal.*?\.sheet\(isPresented: \$showingAdd\) \{", remove_bad_sheets, text, flags=re.DOTALL)


# One more thing: I earlier appended EditTaskModal and EditGoalModal to AdminDashboardView.swift
# But they had compiler error: 
# `cannot force unwrap value of non-optional type 'Double'` in `task.price!`
# task.price is actually Double, not Double? in Models.swift!
# Wait, let's fix the Modals.
text = text.replace("_price = State(initialValue: task.price != nil ? String(format: \"%.2f\", task.price!) : \"\")",
                    "_price = State(initialValue: String(format: \"%.2f\", task.price))")
text = text.replace("task.price != nil ? String(format: \"%.2f\", task.price!) : \"\"",
                    'String(format: "%.2f", task.price)')

text = text.replace("_targetAmount = State(initialValue: String(format: \"%.2f\", goal.targetAmount))",
                    "_targetAmount = State(initialValue: String(format: \"%.2f\", goal.targetAmount))")
text = text.replace("_period = State(initialValue: goal.period ?? \"\")", "_period = State(initialValue: goal.period)")
text = text.replace("TextField(\"Due Date / Note\", text: $period)", "TextField(\"Due Date / Note\", text: $period)") # wait, period is string.

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Fixed sheets and force unwrap")
