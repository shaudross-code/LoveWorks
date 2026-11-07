import subprocess

mongo_uri = "mongodb+srv://labor-admin-hub:d8f0r8j6p6ps73etu7fg@customer-apps.zeiu64.mongodb.net/clockwork_db"
cmd1 = ["/opt/homebrew/bin/mongosh", mongo_uri, "--eval", "db.users.updateOne({email: 'rashaudross@ooutlook.com'}, {$set: {role: 'admin'}})"]
cmd2 = ["/opt/homebrew/bin/mongosh", mongo_uri, "--eval", "db.users.updateOne({email: 'zakiera@loveworks.com'}, {$set: {role: 'admin'}})"]

print('promoting rashaud:')
print(subprocess.run(cmd1, capture_output=True, text=True).stdout)
print('promoting zakiera:')
print(subprocess.run(cmd2, capture_output=True, text=True).stdout)
