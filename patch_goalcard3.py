import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

pattern = re.compile(r"if let imageUrlStr = goal.imageUrl, let url = URL\(string: imageUrlStr\) \{")
replacement = r"if let imageUrlStr = goal.imageUrl, let url = URL(string: APIClient.shared.fullURL(for: imageUrlStr)) {"

new_text = pattern.sub(replacement, text)

with open("iLoveWorks/CommonUI.swift", "w") as f:
    f.write(new_text)
