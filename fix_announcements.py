import requests

login_data = {"email": "admin@loveworks.com", "password": "admin123"}
r = requests.post("https://labor-admin-hub.emergent.host/api/auth/login", json=login_data)
if r.status_code == 200:
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    body = "Version Update: Halloween Theme & Native iOS Dashboard 🎃\nWelcome to the latest build of iLoveWorks! This update brings our dynamic holiday theme system to iOS, syncing the spooky Halloween colors straight from our web platform. We've also finalized the migration to native SwiftUI screens for the Admin and Worker dashboards, removing outdated layouts and significantly improving performance and navigation.\n\nWhat to Test:\n1. Holiday Theme: Verify that the Halloween colors (orange, pink, etc.) and holiday badges load seamlessly across the app on startup.\n2. Native Dashboards: Test navigating between the tabs (Workday, Essentials, Trips, Profile) to ensure the native SwiftUI views load smoothly without any crashing.\n3. Role Validation: Log in as an Admin and confirm you see the correct overview. Then verify standard workers see their specific goals and activities.\n4. Data Sync: Check that the live worker statuses, task scheduling, and payroll endpoints properly fetch from the production database."
    ann_post = requests.post("https://labor-admin-hub.emergent.host/api/announcements", json={
        "title": "Version Update & TestFlight Instructions",
        "body": body,
        "tag": "update"
    }, headers=headers)
    print("Announcement:", ann_post.status_code, ann_post.text)
else:
    print("Login fail:", r.status_code, r.text)
