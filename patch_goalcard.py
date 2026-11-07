import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

# Replace the start of the VStack with the async image block
replacement = """        VStack(alignment: .leading, spacing: 12) {
            if let imageUrlStr = goal.imageUrl, let url = URL(string: imageUrlStr) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 180)
                            .clipped()
                            .cornerRadius(12)
                    } else if phase.error != nil {
                        Rectangle()
                            .fill(Theme.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .cornerRadius(12)
                            .overlay(Image(systemName: "photo").foregroundStyle(.gray.opacity(0.5)))
                    } else {
                        Rectangle()
                            .fill(Theme.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .cornerRadius(12)
                            .overlay(ProgressView())
                    }
                }
                .padding(.bottom, 4)
            }
            
            HStack(alignment: .firstTextBaseline) {"""

# We need to find `VStack(alignment: .leading, spacing: 12) {\n            HStack(alignment: .firstTextBaseline) {`
pattern = re.compile(r"VStack\(alignment: \.leading, spacing: 12\) \{\n\s*HStack\(alignment: \.firstTextBaseline\) \{")
if not pattern.search(text):
    print("Could not find pattern")
else:
    new_text = pattern.sub(replacement, text)
    with open("iLoveWorks/CommonUI.swift", "w") as f:
        f.write(new_text)
    print("Patched!")
