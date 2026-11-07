import sys
from pymongo import MongoClient

mongo_url = "mongodb+srv://labor-admin-hub:d8f0r8j6p6ps73etu7fg@customer-apps.zeiu64.mongodb.net/?appName=labor-admin-hub&maxPoolSize=5&retryWrites=true&timeoutMS=10000&w=majority"
client = MongoClient(mongo_url)
db = client["clockwork_db"]

def update_or_create_admin(email, name, pwd_hash):
    user = db.users.find_one({"email": email})
    if user:
        db.users.update_one({"email": email}, {"$set": {"role": "admin", "name": name, "password_hash": pwd_hash}})
        print(f"Updated {email} to admin")
    else:
        # Note: I need the actual password hash algorithm used by backend
        pass

