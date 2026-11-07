import re

with open("worker_horiz.swift", "r") as f:
    text_horiz = f.read()

# Grab the appended views from HEAD
import subprocess
head_text = subprocess.check_output(["git", "show", "HEAD:iLoveWorks/WorkerDashboardView.swift"]).decode("utf-8")

views_idx = head_text.find("struct WorkerHistoryView: View {")
views_code = head_text[views_idx:]

text = text_horiz.replace("case .history:\n                        WorkerHistoryPlaceholder()", "case .history:\n                        WorkerHistoryView(viewModel: viewModel)")
text = text.replace("case .announcements:\n                        WorkerAnnouncementsPlaceholder()", "case .announcements:\n                        WorkerAnnouncementsView(viewModel: viewModel)")
text = text.replace("case .profile:\n                        WorkerProfilePlaceholder()", "case .profile:\n                        WorkerProfileView()")

# Remove the placeholders in text
text = re.sub(r"// Temporary Placeholders to avoid build failures until those screens are built natively\nstruct WorkerHistoryPlaceholder: View \{ var body: some View \{ Text\(\"History coming soon natively!\"\)\.foregroundStyle\(\.gray\) \} \}\nstruct WorkerAnnouncementsPlaceholder: View \{ var body: some View \{ Text\(\"Announcements coming soon natively!\"\)\.foregroundStyle\(\.gray\) \} \}\nstruct WorkerProfilePlaceholder: View \{ var body: some View \{ Text\(\"Profile coming soon natively!\"\)\.foregroundStyle\(\.gray\) \} \}\n\n", "", text)

# Append views_code
text += "\n" + views_code

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)

