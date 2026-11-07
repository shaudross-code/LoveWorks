import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

# We want to add the Link feature for productLink if it exists. A good place might be immediately after or surrounding the title/owner block. If we make the whole card a link if it exists, or just a small link icon beside the title.
# It seems putting a link icon or making the title a Link might be best. Let's add a Link button right before the target amount in the HStack.

link_button = """
                if let link = goal.productLink, let url = URL(string: link) {
                    Link(destination: url) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.primary)
                    }
                }
                Spacer()"""

# we search for:
#                 }
#                 Spacer()
#                 if let target = goal.targetAmount {

pattern = re.compile(r"\s+\}\n\s+Spacer\(\)\n\s+if let target = goal\.targetAmount \{")

if not pattern.search(text):
    print("Could not find pattern")
else:
    new_text = pattern.sub(r"\n                }\n" + link_button + r"\n                if let target = goal.targetAmount {", text)
    with open("iLoveWorks/CommonUI.swift", "w") as f:
        f.write(new_text)
    print("Patched link!")
