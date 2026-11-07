import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

# We need to render the period/date due. 
# In the existing block we have:
#                VStack(alignment: .leading, spacing: 4) {
#                   GeometryReader { geo in

# Wait, let's see how `CommonUI.swift` currently structures `GoalCard`.
