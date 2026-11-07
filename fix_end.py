import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# Replace the duplicated cases:
pattern = re.compile(r"                        WorkerProfileView\(\)\n                        WorkerAnnouncementsPlaceholder\(\)\n                    case \.sizes:\n                        MySizesView\(\)\n                    case \.profile:\n                        WorkerProfilePlaceholder\(\)")

new_text = pattern.sub("                        WorkerProfileView()", text)
with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(new_text)

