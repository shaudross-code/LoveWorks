import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Let's import the strings from update_edit_views.py dynamically or just parse it
with open("update_edit_views.py", "r") as f:
    update_code = f.read()

task_start = update_code.find('new_task_str = """') + 18
task_end = update_code.find('"""\n\ntext = re.sub(old_task_regex')
new_task_str = update_code[task_start:task_end]

goal_start = update_code.find('new_goal_str = """') + 18
goal_end = update_code.find('"""\ntext = re.sub(old_goal_regex')
new_goal_str = update_code[goal_start:goal_end]

if "struct EditTaskModal: View {" not in text:
    text += "\n" + new_task_str + "\n" + new_goal_str + "\n"

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)

print("Modals appended successfully.")
