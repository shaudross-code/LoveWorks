with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    lines = f.readlines()

new_lines = []
in_head = False
in_main = False
conflict_idx = 0

for line in lines:
    if line.startswith("<<<<<<< HEAD"):
        in_head = True
        conflict_idx += 1
        continue
    elif line.startswith("======="):
        in_head = False
        in_main = True
        continue
    elif line.startswith(">>>>>>>"):
        in_main = False
        continue
    
    if conflict_idx == 1:
        # First conflict: empty vs empty
        if in_head:
            pass # ignore
        elif in_main:
            pass
        else:
            new_lines.append(line)
    elif conflict_idx == 2:
        # Logout
        if in_head:
            pass
        elif in_main:
            new_lines.append(line)
        else:
            new_lines.append(line)
    elif conflict_idx == 3:
        # ScrollView Horizontal Tabs vs background modifier
        if in_head:
            new_lines.append(line)
        elif in_main:
            new_lines.append(line)
        else:
            new_lines.append(line)
    elif conflict_idx == 4:
        # Main views
        if in_head:
            new_lines.append(line)
        elif in_main:
            pass
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.writelines(new_lines)
