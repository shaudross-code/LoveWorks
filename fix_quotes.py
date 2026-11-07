import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

text = text.replace('\\"', '"')

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)
