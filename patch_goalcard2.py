import re

with open("iLoveWorks/CommonUI.swift", "r") as f:
    text = f.read()

replacement = """        VStack(alignment: .leading, spacing: 12) {
            if let imageUrlStr = goal.imageUrl, let url = URL(string: imageUrlStr.hasPrefix("/") ? APIClient.shared.baseURL + imageUrlStr : imageUrlStr) {
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

# Because I already replaced the start in patch_goalcard.py
# Let's just find the string `if let imageUrlStr = goal.imageUrl, let url = URL(string: imageUrlStr) {`
# and replace it with:
# `if let imageUrlStr = goal.imageUrl, let url = URL(string: imageUrlStr.hasPrefix("/") ? APIClient.shared.baseURL.replacingOccurrences(of: "/api", with: "") + imageUrlStr : imageUrlStr) {`

# The API baseURL is usually `https://labor-admin-hub.emergent.host/api`
# If they uploaded a file, it's typically in `/uploads/` which means `https://labor-admin-hub.emergent.host/uploads/...`

# Actually, let's look at what `APIClient.shared.baseURL` is defined as.
