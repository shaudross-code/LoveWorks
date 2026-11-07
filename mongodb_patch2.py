from pymongo import MongoClient
import certifi

# User's provided db string from earlier connection context snippet
uri = "mongodb+srv://labor-admin-hub:d8f0r8j6p6ps73etu7fg@customer-apps.zeiu64.mongodb.net/?appName=labor-admin-hub&maxPoolSize=5&retryWrites=true&timeoutMS=10000&w=majority"

try:
    client = MongoClient(uri, tlsCAFile=certifi.where())
    db = client.get_database("test")  
    
    announcements_collection = db["announcements"]
    
    announcement = {
        "title": "Build 1.0.3 - TestFlight Updates (Nov 7)",
        "body": "New changes in this test flight include: \n- Product Links on Goals/Trips are now completely native and clickable.\n- Tasks that are completed will automatically drop to the bottom of the list.\n- Task Alarms natively trigger lockscreen pushes using iOS UNUserNotificationCenter. Admins can enforce mandatory alarms.",
        "tag": "Update",
        "createdAt": "2026-11-07T16:00:00Z"
    }
    
    result = announcements_collection.insert_one(announcement)
    print("Inserted! ID:", result.inserted_id)
except Exception as e:
    print("Error:", e)

