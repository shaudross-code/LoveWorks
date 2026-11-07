import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Make AdminWorkerCard responsive to the "grid" bug noted in iteration 10
# We ensure there's a frame modifier wrapping the weekly strip elements and wrapping buttons
worker_card_regex = r"""                                AdminWorkerCard\(status: status\)
                                    \.background\(Theme\.surface\)
                                    \.cornerRadius\(16\)
                                    \.contentShape\(Rectangle\(\)\)
                                    \.onTapGesture \{ editingWorker = status\.worker \}"""
worker_card_new = """                                AdminWorkerCard(status: status)
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .background(Theme.surface)
                                    .cornerRadius(16)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingWorker = status.worker }"""
text = text.replace(worker_card_regex, worker_card_new)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

print("Applied container flex boundaries")
