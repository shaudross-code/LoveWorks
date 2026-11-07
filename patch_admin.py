with open("backend/server.py", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if "class UpdateWorkerRequest(BaseModel):" in line:
        new_lines.append("    role: Optional[str] = None\n")
    if "update[\"name\"] = req.name.strip()" in line:
        new_lines.append("    if req.role is not None:\n        update[\"role\"] = req.role\n")

with open("backend/server.py", "w") as f:
    f.writelines(new_lines)
