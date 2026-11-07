import re
with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    aview = f.read()

aview = re.sub(r'case \.goals:\s*AdminGoalsPlaceholder\(\)', 'case .goals:\\n                        AdminGoalsView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.trips:\s*AdminTripsPlaceholder\(\)', 'case .trips:\\n                        AdminTripsView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.payroll:\s*AdminPayrollPlaceholder\(\)', 'case .payroll:\\n                        AdminPayrollView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.announcements:\s*AdminAnnouncementsPlaceholder\(\)', 'case .announcements:\\n                        AdminAnnouncementsView(viewModel: viewModel)', aview)
aview = re.sub(r'case \.profile:\s*AdminProfilePlaceholder\(\)', 'case .profile:\\n                        AdminProfileView()', aview)

# Remove the unused placeholders
aview = re.sub(r'// Temporary Placeholders.*?\n(struct Admin.*?Placeholder.*?\n)+', '', aview, flags=re.DOTALL)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(aview)
