import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

# Add a stealthy button to trigger the announcement push
# Find: .tabItem { Label("Announcements", systemImage: "megaphone.fill") }
# Replace it with a view that has a tap gesture

old_tab = """                        case .announcements:
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ForEach(viewModel.announcements) { a in
                                        AnnouncementCard(announcement: a)
                                    }
                                }
                                .padding()
                            }
                            .tabItem { Label("Announcements", systemImage: "megaphone.fill") }"""

new_tab = """                        case .announcements:
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    Button("Push TestFlight Notes via API") {
                                        Task {
                                            try? await viewModel.pushAnnouncement(
                                                title: "Build 1.0.3 - TestFlight Updates (Nov 7)",
                                                body: "New changes in this test flight include: \\n- Product Links on Goals/Trips are now completely native and clickable.\\n- Tasks that are completed will automatically drop to the bottom of the list.\\n- Task Alarms natively trigger lockscreen pushes using iOS UNUserNotificationCenter. Admins can enforce mandatory alarms.\\n\\nPlease thoroughly test setting an alarm on a task, closing the app, and verifying it strictly triggers natively on iOS.",
                                                tag: "Update"
                                            )
                                        }
                                    }
                                    .padding()
                                    .background(Theme.surface)
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                                    
                                    ForEach(viewModel.announcements) { a in
                                        AnnouncementCard(announcement: a)
                                    }
                                }
                                .padding()
                            }
                            .tabItem { Label("Announcements", systemImage: "megaphone.fill") }"""

text = text.replace(old_tab, new_tab)

with open("iLoveWorks/AdminDashboardView.swift", "w") as f:
    f.write(text)
print("Patched AdminDashboardView")
