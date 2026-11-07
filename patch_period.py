import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

# We need to render the "period", which usually signifies the target date or timeframe.
# We have createdAt as well, but usually period is what we want for "dates due".
# Let's add it right under the owner's name.

owner_str = """                    if let owner = goal.owner?.name {
                        Text(owner)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }"""

owner_with_period = """                    if let owner = goal.owner?.name {
                        Text(owner)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    if let period = goal.period {
                        Text("Due: " + period)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.danger)
                    }"""

text = text.replace(owner_str, owner_with_period)

with open("iLoveWorks/CommonUI.swift", "w") as f:
    f.write(text)

print("Patched period!")
