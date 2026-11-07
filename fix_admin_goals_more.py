import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add Goals to MoreView
more_view_pattern = r"(NavigationLink\(destination: AdminTripsView\(viewModel: viewModel\)\) \{\n.*?Label\(\"Trips\", systemImage: \"airplane\"\)\n.*?\})"

replacement = r"""
                        NavigationLink(destination: AdminGoalsView(viewModel: viewModel)) {
                            Label("Goals", systemImage: "target")
                        }
\1"""

new_text = re.sub(more_view_pattern, replacement, text)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(new_text)

