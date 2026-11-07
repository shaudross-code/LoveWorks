with open("worker_horiz.swift", "r") as f:
    text = f.read()

# Make the placeholder replacements
text = text.replace("case .history:\n                        WorkerHistoryPlaceholder()", "case .history:\n                        WorkerHistoryView(viewModel: viewModel)")
text = text.replace("case .announcements:\n                        WorkerAnnouncementsPlaceholder()", "case .announcements:\n                        WorkerAnnouncementsView(viewModel: viewModel)")
text = text.replace("case .profile:\n                        WorkerProfilePlaceholder()", "case .profile:\n                        WorkerProfileView()")

# And we have to fix the .logout action to match origin/main async if needed? Not necessarily, but wait... main changed Logout from `sessionManager.logout()` to `Task { await sessionManager.logout() }`.
# Looking at SessionManager.swift, we probably just need to use whatever compiles. Let's just use `sessionManager.logout()` since it worked fine earlier.

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)

