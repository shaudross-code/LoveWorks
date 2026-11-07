import urllib.request
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# We need an admin login token first.
login_req = urllib.request.Request("https://labor-admin-hub.emergent.host/api/login", method="POST")
login_req.add_header("Content-Type", "application/json")
login_payload = {"email":"b@emergent.host","password":"password"}

tok = ""
with urllib.request.urlopen(login_req, data=json.dumps(login_payload).encode('utf-8'), context=ctx) as r:
    data = json.loads(r.read())
    tok = data.get("token", "")

print("Got token:", tok)

req = urllib.request.Request("https://labor-admin-hub.emergent.host/api/announcements", method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", f"Bearer {tok}")

payload = {
    "title": "Build 1.0.3 - TestFlight Updates (Nov 7)",
    "body": "New changes in this test flight include: \n- Product Links on Goals/Trips are now completely native and clickable.\n- Tasks that are completed will automatically drop to the bottom of your task list to stay out of the way.\n- You can now set local Task Alarms for yourself! Tap the bell icon on any task. Admins also have the ability to enforce mandatory alarms that users cannot turn off.",
    "tag": "Update"
}

try:
    with urllib.request.urlopen(req, data=json.dumps(payload).encode('utf-8'), context=ctx) as response:
        print("Pushed announcement!")
except Exception as e:
    print(f"Error: {e}")
