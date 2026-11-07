import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Layout: Fix AdminWorkersView so it matches exactly
worker_card_regex = r"""                                AdminWorkerCard\(status: status\)
                                    \.contentShape\(Rectangle\(\)\)
                                    \.onTapGesture \{ editingWorker = status\.worker \}"""
worker_card_new = """                                AdminWorkerCard(status: status)
                                    .background(Theme.surface)
                                    .cornerRadius(16)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingWorker = status.worker }"""
text = text.replace(worker_card_regex, worker_card_new)

# EditTaskModal layout fix to explicitly match AddTaskView design parity
task_modal_regex = r"""                        VStack\(alignment: \.leading, spacing: 8\) \{
                            Text\("TITLE"\)
                                \.font\(\.system\(size: 10, weight: \.bold\)\)
                                \.foregroundStyle\(Theme\.textMuted\)
                            TextField\("Task Name", text: \$title\)
                                \.padding\(\)
                                \.background\(Theme\.surface\)
                                \.cornerRadius\(12\)
                                \.overlay\(RoundedRectangle\(cornerRadius: 12\)\.stroke\(Theme\.border, lineWidth: 1\)\)
                                \.foregroundStyle\(Theme\.textMain\)
                        \}"""
if task_modal_regex not in text:
    pass

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

