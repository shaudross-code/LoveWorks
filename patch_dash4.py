with open("iLoveWorks/WorkerDashboardView.swift.bak", "r") as f:
    orig = f.read()

with open("replacement.swift", "r") as f:
    rep = f.read()

start_idx = orig.find("struct WorkerDashboardMainView: View {")
end_idx = orig.find("struct ActivityPickerView: View {")

if start_idx == -1 or end_idx == -1:
    print("Could not find markers")
    exit(1)

new_content = orig[:start_idx] + rep + "\n\n" + orig[end_idx:]

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(new_content)
print("Safely patched WorkerDashboardView!")
