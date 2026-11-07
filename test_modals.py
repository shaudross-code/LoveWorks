import re

with open("iLoveWorks/AdminDashboardView.swift", "r") as f:
    text = f.read()

if "struct AdminEssentialsView: View" in text:
    print("Has AdminEssentialsView")

if "struct AdminAnnouncementsView: View" in text:
    print("Has AdminAnnouncementsView")
