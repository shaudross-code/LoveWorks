# The list of tasks rendered is `ForEach(viewModel.tasks) { task in }`.
# The user wants completed tasks to automatically drop to the bottom of the list.
# We can just sort `viewModel.tasks` locally right before placing them in the ForEach loop, or better yet, add a computed property on the ViewModel to provide the sorted tasks, or just sort them directly in the ForEach.

print("We should sort `viewModel.tasks` in WorkerDashboardView.swift or WorkerViewModel.")
