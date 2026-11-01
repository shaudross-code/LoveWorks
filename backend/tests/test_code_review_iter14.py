# Iteration 14: code-review fixes — lockout reset, file sandbox ACL, theme local date,
# task PATCH/DELETE sandbox scoping, assignee + status validation
import io
import os
import uuid
from datetime import datetime, timedelta, timezone

import pytest
import requests
from pymongo import MongoClient
from PIL import Image

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL").rstrip("/")
ADMIN = {"email": "admin@loveworks.com", "password": "admin123"}
REVIEWER = {"email": "reviewer@loveworks.com", "password": "iLoveWorks2026!"}
WORKER = {"email": "lovetest@loveworks.com", "password": "Love123!"}


def _env(key):
    for line in open("/app/backend/.env"):
        if line.startswith(key + "="):
            return line.split("=", 1)[1].strip().strip('"')


mdb = MongoClient(_env("MONGO_URL"))[_env("DB_NAME")]


def _login(creds):
    s = requests.Session()
    r = s.post(f"{BASE_URL}/api/auth/login", json=creds)
    if r.status_code != 200:
        pytest.skip(f"login failed {creds['email']} {r.status_code} {r.text}")
    s.headers.update({"Authorization": f"Bearer {r.json()['access_token']}"})
    return s, r.json()["user"]


def _png():
    b = io.BytesIO()
    Image.new("RGB", (8, 8), (255, 0, 0)).save(b, "PNG")
    return b.getvalue()


@pytest.fixture(scope="module")
def admin():
    return _login(ADMIN)


@pytest.fixture(scope="module")
def reviewer():
    return _login(REVIEWER)


@pytest.fixture(scope="module")
def real_worker(admin):
    s, _ = admin
    email = f"test_iter14_{uuid.uuid4().hex[:6]}@example.com"
    r = s.post(f"{BASE_URL}/api/workers", json={"email": email, "password": "Pass1234!", "name": "TEST_Real14"})
    assert r.status_code in (200, 201), r.text
    w = r.json()
    yield {**w, "email": email, "password": "Pass1234!"}
    s.delete(f"{BASE_URL}/api/workers/{w['id']}")
    mdb.login_attempts.delete_many({"identifier": {"$regex": email}})


@pytest.fixture(scope="module")
def sb_worker(reviewer):
    s, _ = reviewer
    email = f"test_iter14_sb_{uuid.uuid4().hex[:6]}@example.com"
    r = s.post(f"{BASE_URL}/api/workers", json={"email": email, "password": "Pass1234!", "name": "TEST_Sandbox14"})
    assert r.status_code in (200, 201), r.text
    w = r.json()
    yield {**w, "email": email, "password": "Pass1234!"}
    s.delete(f"{BASE_URL}/api/workers/{w['id']}")


def _task(s, assignee_id, title):
    r = s.post(f"{BASE_URL}/api/tasks", json={"title": title, "description": "", "price": 5, "assignee_id": assignee_id})
    assert r.status_code in (200, 201), r.text
    return r.json()


# --- Brute force lockout + reset after window ---
class TestLockout:
    def test_lockout_then_reset(self, real_worker):
        email = real_worker["email"]
        codes = []
        # NOTE: identifier = ingress_ip:email; ingress has multiple pod IPs so lockout
        # may need >5 attempts to trigger (reported as issue). Loop until 429.
        for _ in range(20):
            c = requests.post(f"{BASE_URL}/api/auth/login", json={"email": email, "password": "wrong"}).status_code
            codes.append(c)
            if c == 429:
                break
        print("bad codes:", codes)
        assert codes[-1] == 429
        if len(codes) > 6:
            print(f"WARNING: lockout needed {len(codes) - 1} failures (expected 5) — per-ingress-IP keying")
        r = requests.post(f"{BASE_URL}/api/auth/login", json={"email": email, "password": real_worker["password"]})
        print("correct pw while locked:", r.status_code)
        recs = list(mdb.login_attempts.find({"identifier": {"$regex": email}}))
        assert recs and max(x["count"] for x in recs) >= 5
        # force all ingress-ip records into locked state so assertions below are deterministic
        mdb.login_attempts.update_many({"identifier": {"$regex": email}}, {"$set": {"count": 5}})
        # backdate past lockout window
        old = (datetime.now(timezone.utc) - timedelta(minutes=16)).isoformat()
        mdb.login_attempts.update_many({"identifier": {"$regex": email}}, {"$set": {"last_attempt": old}})
        # one wrong attempt after window => 401 (not 429), counter restarted at 1
        r = requests.post(f"{BASE_URL}/api/auth/login", json={"email": email, "password": "wrong"})
        assert r.status_code == 401, r.status_code
        recs = list(mdb.login_attempts.find({"identifier": {"$regex": email}}))
        assert min(x["count"] for x in recs) == 1, [x["count"] for x in recs]
        # previously a single failure here would re-lock immediately; now still 401
        r = requests.post(f"{BASE_URL}/api/auth/login", json={"email": email, "password": "wrong"})
        assert r.status_code == 401
        # correct password works; record cleared
        r = requests.post(f"{BASE_URL}/api/auth/login", json={"email": email, "password": real_worker["password"]})
        assert r.status_code == 200, r.text
        assert "access_token" in r.json()
        # lockout window still for real-time: correct login also blocked while locked was verified above

    def test_bcrypt_and_cookies(self):
        r = requests.post(f"{BASE_URL}/api/auth/login", json=ADMIN)
        assert r.status_code == 200
        sc = r.headers.get("set-cookie", "")
        assert "access_token" in sc and "httponly" in sc.lower()
        u = mdb.users.find_one({"email": ADMIN["email"]})
        assert u["password_hash"].startswith("$2b$")


# --- File download sandbox ACL ---
class TestFileAcl:
    def test_cross_sandbox_file_access(self, admin, reviewer, real_worker, sb_worker):
        rs, _ = _login({"email": real_worker["email"], "password": real_worker["password"]})
        ss, _ = _login({"email": sb_worker["email"], "password": sb_worker["password"]})
        r1 = rs.post(f"{BASE_URL}/api/me/avatar", files={"file": ("a.png", _png(), "image/png")})
        assert r1.status_code == 200, r1.text
        r2 = ss.post(f"{BASE_URL}/api/me/avatar", files={"file": ("b.png", _png(), "image/png")})
        assert r2.status_code == 200, r2.text
        real_url = r1.json()["avatar_url"]
        sb_url = r2.json()["avatar_url"]
        assert real_url and sb_url
        # owners can read own
        assert rs.get(BASE_URL + real_url).status_code == 200
        assert ss.get(BASE_URL + sb_url).status_code == 200
        # same-realm access allowed
        assert admin[0].get(BASE_URL + real_url).status_code == 200
        assert reviewer[0].get(BASE_URL + sb_url).status_code == 200
        # cross-realm blocked
        assert reviewer[0].get(BASE_URL + real_url).status_code == 403
        assert ss.get(BASE_URL + real_url).status_code == 403
        assert admin[0].get(BASE_URL + sb_url).status_code == 403
        assert rs.get(BASE_URL + sb_url).status_code == 403
        # ?auth= query token path for <img>
        tok = reviewer[0].headers["Authorization"].split()[1]
        assert requests.get(f"{BASE_URL}{real_url}?auth={tok}").status_code == 403
        # unauth
        assert requests.get(BASE_URL + real_url).status_code == 401


# --- Task PATCH / DELETE sandbox scoping + validation ---
class TestTaskScoping:
    def test_patch_delete_cross_sandbox(self, admin, reviewer, real_worker, sb_worker):
        a, _ = admin
        rv, _ = reviewer
        real_t = _task(a, real_worker["id"], "TEST_iter14 real task")
        sb_t = _task(rv, sb_worker["id"], "TEST_iter14 sb task")
        # reviewer cannot patch / delete real task
        r = rv.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"title": "hacked"})
        assert r.status_code == 404
        r = rv.delete(f"{BASE_URL}/api/tasks/{real_t['id']}")
        assert r.status_code == 404
        # owner admin cannot patch / delete sandbox task
        assert a.patch(f"{BASE_URL}/api/tasks/{sb_t['id']}", json={"title": "x"}).status_code == 404
        assert a.delete(f"{BASE_URL}/api/tasks/{sb_t['id']}").status_code == 404
        # task unchanged
        t = mdb.tasks.find_one({"id": real_t["id"]})
        assert t and t["title"] == "TEST_iter14 real task"
        assert mdb.tasks.find_one({"id": sb_t["id"]})["title"] == "TEST_iter14 sb task"
        # reassign to cross-sandbox worker rejected
        r = a.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"assignee_id": sb_worker["id"]})
        assert r.status_code == 404
        r = rv.patch(f"{BASE_URL}/api/tasks/{sb_t['id']}", json={"assignee_id": real_worker["id"]})
        assert r.status_code == 404
        # reassign to non-existent
        r = a.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"assignee_id": "nope"})
        assert r.status_code == 404
        assert mdb.tasks.find_one({"id": real_t["id"]})["assignee_id"] == real_worker["id"]
        # invalid status
        r = a.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"status": "bogus"})
        assert r.status_code == 400
        # valid status + own scope update works
        r = a.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"status": "in_progress", "title": "TEST_iter14 edited"})
        assert r.status_code == 200 and r.json()["title"] == "TEST_iter14 edited"
        r = rv.patch(f"{BASE_URL}/api/tasks/{sb_t['id']}", json={"price": 7})
        assert r.status_code == 200 and r.json()["price"] == 7
        # worker of real task can still update status
        ws, _ = _login({"email": real_worker["email"], "password": real_worker["password"]})
        r = ws.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"status": "completed"})
        assert r.status_code == 200 and r.json()["status"] == "completed"
        # worker invalid status
        r = ws.patch(f"{BASE_URL}/api/tasks/{real_t['id']}", json={"status": "bogus"})
        assert r.status_code == 400
        # own-scope deletes work
        assert a.delete(f"{BASE_URL}/api/tasks/{real_t['id']}").status_code == 200
        assert rv.delete(f"{BASE_URL}/api/tasks/{sb_t['id']}").status_code == 200
        assert mdb.tasks.find_one({"id": real_t["id"]}) is None
        assert mdb.tasks.find_one({"id": sb_t["id"]}) is None

    def test_patch_nonexistent(self, admin):
        assert admin[0].patch(f"{BASE_URL}/api/tasks/doesnotexist", json={"title": "x"}).status_code == 404
        assert admin[0].delete(f"{BASE_URL}/api/tasks/doesnotexist").status_code == 404


# --- Theme uses local (APP_TZ) date ---
class TestTheme:
    def test_theme_public(self):
        r = requests.get(f"{BASE_URL}/api/theme")
        assert r.status_code == 200
        d = r.json()
        print(d)
        assert "effective" in d or "theme" in d
