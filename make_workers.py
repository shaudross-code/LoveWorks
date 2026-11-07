import requests

login_data = {"email": "admin@loveworks.com", "password": "admin123"}
r = requests.post("https://labor-admin-hub.emergent.host/api/auth/login", json=login_data)
if r.status_code == 200:
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Create Rashaud
    u1 = requests.post("https://labor-admin-hub.emergent.host/api/workers", json={
        "email": "rashaudross@ooutlook.com",
        "password": "admin123",
        "name": "Rashaud Ross"
    }, headers=headers)
    print("Rashaud:", u1.status_code, u1.text)
    
    # Create Zakiera
    u2 = requests.post("https://labor-admin-hub.emergent.host/api/workers", json={
        "email": "zakiera@loveworks.com",
        "password": "admin123",
        "name": "Zakiera Ross"
    }, headers=headers)
    print("Zakiera:", u2.status_code, u2.text)
else:
    print("Login fail:", r.status_code, r.text)
