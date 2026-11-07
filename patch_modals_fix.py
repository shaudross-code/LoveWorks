import re

with open("patch_modals.py", "r") as f:
    text = f.read()

# I need to change:
# old = "@State private var isSubmitting = false"
# to:
# old_regex = r"struct EditWorkerModal: View \{.*?\}" etc but it's easier to just restrict the replace.
text = text.replace('text = text.replace(old, new)', 'text = text.replace("    @State private var isSubmitting = false\\n    \\n    var body: some View {\\n        NavigationView {\\n            ZStack {\\n                Theme.background.ignoresSafeArea()\\n                \\n                ScrollView {\\n                    VStack(spacing: 24) {\\n                        if let urlString = worker.avatarUrl", new + "\\n    \\n    var body: some View {\\n        NavigationView {\\n            ZStack {\\n                Theme.background.ignoresSafeArea()\\n                \\n                ScrollView {\\n                    VStack(spacing: 24) {\\n                        if let urlString = worker.avatarUrl")')

with open("patch_modals.py", "w") as f:
    f.write(text)
