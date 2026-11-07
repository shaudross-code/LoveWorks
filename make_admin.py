import requests

login_data = {"email": "admin@loveworks.com", "password": "admin123"}
r = requests.post("https://labor-admin-hub.emergent.host/api/auth/login", json=login_data)
if r.status_code == 200:
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    workers_resp = requests.get("https://labor-admin-hub.emergent.host/api/payroll", headers=headers)
    workers = workers_resp.json()
    
    for w in workers:
        person = w.get("worker", {})
        if person.get("email") in ("rashaudross@ooutlook.com", "zakiera@loveworks.com"):
            u = requests.patch(f"https://labor-admin-hub.emergent.host/api/workers/{person['id']}", json={"name": person["name"] + " (Admin)"}, headers=headers)
            print("Updated Name for test", person["name"], ":", u.status_code, u.text)
else:
    print("Login fail:", r.status_code, r.text)
