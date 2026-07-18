# Auth Testing Playbook

Admin: `admin@clockwork.com` / `admin123`

## API tests
```
# Login (sets cookies)
curl -c c.txt -X POST $URL/api/auth/login -H "Content-Type: application/json" \
  -d '{"email":"admin@clockwork.com","password":"admin123"}'

# Me
curl -b c.txt $URL/api/auth/me

# Create worker
curl -b c.txt -X POST $URL/api/workers -H "Content-Type: application/json" \
  -d '{"email":"worker@clockwork.com","password":"worker123","name":"Test Worker"}'

# Worker login
curl -c w.txt -X POST $URL/api/auth/login -H "Content-Type: application/json" \
  -d '{"email":"worker@clockwork.com","password":"worker123"}'

# Worker clock-in
curl -b w.txt -X POST $URL/api/time/clock-in
```
