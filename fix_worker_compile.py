with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    lines = f.readlines()

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    for line in lines:
        if "case .tasks, .goals, .payroll:" in line:
            pass
        elif "Text(\"Not available for Worker\")" in line:
            pass
        else:
            f.write(line)

