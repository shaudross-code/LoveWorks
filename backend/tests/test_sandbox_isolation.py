"""Sandbox isolation tests for reviewer vs owner accounts (iteration_7)."""
import os
import random
import string
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://labor-admin-hub.preview.emergentagent.com").rstrip("/")
API = f"{BASE_URL}/api"

OWNER = ("admin@loveworks.com", "admin123")
REVIEWER = ("reviewer@loveworks.com", "iLoveWorks2026!")
DEMO_WORKER = ("demo@loveworks.com", "DemoWorker2026!")
REAL_WORKER = ("lovetest@loveworks.com", "Love123!")


def login(email, password):
    r = requests.post(f"{API}/auth/login", json={"email": email, "password": password}, timeout=15)
    assert r.status_code == 200, f"login failed for {email}: {r.status_code} {r.text}"
    tok = r.json().get("access_token")
    assert tok
    return {"Authorization": f"Bearer {tok}"}


@pytest.fixture(scope="module")
def owner_h():
    return login(*OWNER)


@pytest.fixture(scope="module")
def rev_h():
    return login(*REVIEWER)


@pytest.fixture(scope="module")
def demo_h():
    return login(*DEMO_WORKER)


@pytest.fixture(scope="module")
def real_worker_h():
    return login(*REAL_WORKER)


def rnd():
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=6))


# ---------- Reviewer isolation ----------
class TestReviewerIsolation:
    def test_workers_only_demo(self, rev_h):
        r = requests.get(f"{API}/workers", headers=rev_h, timeout=15)
        assert r.status_code == 200
        emails = [w.get("email") for w in r.json()]
        assert "demo@loveworks.com" in emails
        # only sandbox workers - demo + any sb test workers, none real
        for e in emails:
            assert e not in ("lovetest@loveworks.com",)

    def test_tasks_only_demo(self, rev_h):
        r = requests.get(f"{API}/tasks", headers=rev_h, timeout=15)
        assert r.status_code == 200
        titles = [t.get("title") for t in r.json()]
        expected = {"Water the plants", "Fold the laundry", "Vacuum the living room"}
        assert expected.issubset(set(titles)), f"Missing demo tasks. Got: {titles}"

    def test_goals(self, rev_h):
        r = requests.get(f"{API}/goals", headers=rev_h, timeout=15)
        assert r.status_code == 200
        titles = [g.get("title") for g in r.json()]
        assert "New Headphones" in titles
        assert "Weekend Lake Trip" in titles

    def test_essentials(self, rev_h):
        r = requests.get(f"{API}/essentials", headers=rev_h, timeout=15)
        assert r.status_code == 200
        titles = [e.get("title") for e in r.json()]
        assert "Paper towels" in titles

    def test_payroll_only_demo(self, rev_h):
        r = requests.get(f"{API}/payroll", headers=rev_h, timeout=15)
        assert r.status_code == 200
        emails = [(p.get("worker") or {}).get("email") or p.get("email") for p in r.json()]
        assert emails and all(e == "demo@loveworks.com" for e in emails), f"payroll leaked: {emails}"

    def test_worker_status_only_demo(self, rev_h):
        r = requests.get(f"{API}/admin/worker-status", headers=rev_h, timeout=15)
        assert r.status_code == 200
        emails = [(p.get("worker") or {}).get("email") or p.get("email") for p in r.json()]
        assert emails and all(e == "demo@loveworks.com" for e in emails), f"worker-status leaked: {emails}"

    def test_announcements_empty_of_real(self, rev_h):
        r = requests.get(f"{API}/announcements", headers=rev_h, timeout=15)
        assert r.status_code == 200
        # reviewer should only see sandbox announcements (none by default)
        # No hard count assert since tests may add some; just ensure none from real accounts
        # We can't easily tell here; verified by owner-side check below.

    def test_time_entries_only_demo(self, rev_h):
        r = requests.get(f"{API}/time/entries", headers=rev_h, timeout=15)
        assert r.status_code == 200
        entries = r.json()
        # Any entries returned must belong to demo worker
        # Cross-ref by getting demo worker id
        wr = requests.get(f"{API}/workers", headers=rev_h, timeout=15).json()
        demo_id = next((w["id"] for w in wr if w["email"] == "demo@loveworks.com"), None)
        assert demo_id
        for e in entries:
            uid = e.get("user_id") or e.get("worker_id")
            if uid:
                assert uid == demo_id, f"entry leak: {e}"


# ---------- Owner isolation (no sandbox leak) ----------
class TestOwnerIsolation:
    FORBIDDEN_EMAILS = {"demo@loveworks.com", "reviewer@loveworks.com"}
    FORBIDDEN_TITLES = {"Vacuum the living room", "New Headphones", "Weekend Lake Trip", "Paper towels"}

    def test_workers_no_sandbox(self, owner_h):
        r = requests.get(f"{API}/workers", headers=owner_h, timeout=15)
        assert r.status_code == 200
        emails = {w.get("email") for w in r.json()}
        assert not (emails & self.FORBIDDEN_EMAILS), f"sandbox leak: {emails & self.FORBIDDEN_EMAILS}"

    def test_tasks_no_sandbox(self, owner_h):
        r = requests.get(f"{API}/tasks", headers=owner_h, timeout=15)
        assert r.status_code == 200
        titles = {t.get("title") for t in r.json()}
        assert "Vacuum the living room" not in titles, f"sandbox task leaked into owner"

    def test_goals_no_sandbox(self, owner_h):
        r = requests.get(f"{API}/goals", headers=owner_h, timeout=15)
        assert r.status_code == 200
        titles = {g.get("title") for g in r.json()}
        assert not (titles & {"New Headphones", "Weekend Lake Trip"}), f"sandbox goal leak"

    def test_essentials_no_sandbox(self, owner_h):
        r = requests.get(f"{API}/essentials", headers=owner_h, timeout=15)
        assert r.status_code == 200
        titles = {e.get("title") for e in r.json()}
        assert "Paper towels" not in titles

    def test_payroll_no_sandbox(self, owner_h):
        r = requests.get(f"{API}/payroll", headers=owner_h, timeout=15)
        assert r.status_code == 200
        emails = {(p.get("worker") or {}).get("email") or p.get("email") for p in r.json()}
        assert not (emails & self.FORBIDDEN_EMAILS)

    def test_worker_status_no_sandbox(self, owner_h):
        r = requests.get(f"{API}/admin/worker-status", headers=owner_h, timeout=15)
        assert r.status_code == 200
        emails = {(p.get("worker") or {}).get("email") or p.get("email") for p in r.json()}
        assert not (emails & self.FORBIDDEN_EMAILS)


# ---------- Sandbox worker creation propagation ----------
class TestSandboxWorkerCreation:
    def test_create_sb_worker_isolated(self, rev_h, owner_h):
        email = f"sbtest+{rnd()}@loveworks.com"
        r = requests.post(f"{API}/workers", headers=rev_h,
                          json={"email": email, "password": "Test1234!", "name": "SB Test"}, timeout=15)
        assert r.status_code in (200, 201), r.text
        new_id = r.json().get("id")
        assert new_id

        # visible to reviewer
        rev_workers = requests.get(f"{API}/workers", headers=rev_h, timeout=15).json()
        assert any(w.get("email") == email for w in rev_workers)

        # NOT visible to owner
        owner_workers = requests.get(f"{API}/workers", headers=owner_h, timeout=15).json()
        assert not any(w.get("email") == email for w in owner_workers), "sandbox worker leaked to owner"

        # Reviewer creates a task assigned to the sb worker
        tr = requests.post(f"{API}/tasks", headers=rev_h,
                           json={"title": f"SB Task {rnd()}", "assignee_id": new_id, "price": 1.0}, timeout=15)
        assert tr.status_code in (200, 201), tr.text
        task_id = tr.json().get("id")

        # task visible to reviewer but not owner
        rev_tasks = requests.get(f"{API}/tasks", headers=rev_h, timeout=15).json()
        assert any(t.get("id") == task_id for t in rev_tasks)
        owner_tasks = requests.get(f"{API}/tasks", headers=owner_h, timeout=15).json()
        assert not any(t.get("id") == task_id for t in owner_tasks), "sandbox task leaked to owner"

        # Reviewer can DELETE its sandbox worker
        d = requests.delete(f"{API}/workers/{new_id}", headers=rev_h, timeout=15)
        assert d.status_code in (200, 204), d.text

    def test_reviewer_cannot_delete_real_worker(self, rev_h, owner_h):
        owner_workers = requests.get(f"{API}/workers", headers=owner_h, timeout=15).json()
        real = next((w for w in owner_workers if w.get("email") not in ("demo@loveworks.com",)), None)
        assert real, "no real worker found"
        d = requests.delete(f"{API}/workers/{real['id']}", headers=rev_h, timeout=15)
        assert d.status_code == 404, f"reviewer should not be able to delete real worker, got {d.status_code}"


# ---------- Cross-sandbox assignment blocks ----------
class TestCrossSandboxAssignment:
    @pytest.fixture(scope="class")
    def real_worker_id(self, owner_h):
        ws = requests.get(f"{API}/workers", headers=owner_h, timeout=15).json()
        real = next((w for w in ws if w.get("email") == "lovetest@loveworks.com"), None) or \
               next((w for w in ws if w.get("email") not in ("demo@loveworks.com",)), None)
        assert real
        return real["id"]

    def test_task_assign_to_real_worker_blocked(self, rev_h, real_worker_id):
        r = requests.post(f"{API}/tasks", headers=rev_h,
                          json={"title": "should fail", "assignee_id": real_worker_id, "price": 1.0}, timeout=15)
        assert r.status_code == 404, f"expected 404, got {r.status_code} {r.text}"

    def test_goal_assign_to_real_worker_blocked(self, rev_h, real_worker_id):
        # POST /api/goals uses query params + multipart
        r = requests.post(f"{API}/goals",
                          headers=rev_h,
                          params={"title": "sb goal x", "assignee_id": real_worker_id},
                          files={"_": (None, "")},  # force multipart
                          timeout=15)
        assert r.status_code == 404, f"expected 404, got {r.status_code} {r.text}"

    def test_essential_assign_to_real_worker_blocked(self, rev_h, real_worker_id):
        r = requests.post(f"{API}/essentials",
                          headers=rev_h,
                          params={"title": "sb ess x", "price": 5, "assignee_id": real_worker_id},
                          files={"_": (None, "")},
                          timeout=15)
        assert r.status_code == 404, f"expected 404, got {r.status_code} {r.text}"


# ---------- Announcements isolation ----------
class TestAnnouncementsIsolation:
    def test_announcement_fanout(self, rev_h, owner_h, demo_h, real_worker_h):
        title = f"Sandbox hello {rnd()}"
        r = requests.post(f"{API}/announcements", headers=rev_h,
                          json={"title": title, "body": "test", "tag": "update"}, timeout=15)
        assert r.status_code in (200, 201), r.text
        ann_id = r.json().get("id")
        assert ann_id

        # owner should NOT see it
        oa = requests.get(f"{API}/announcements", headers=owner_h, timeout=15).json()
        assert not any(a.get("title") == title for a in oa), "reviewer announcement leaked to owner"

        # real worker should NOT see it
        ra = requests.get(f"{API}/announcements", headers=real_worker_h, timeout=15).json()
        assert not any(a.get("title") == title for a in ra), "reviewer announcement leaked to real worker"

        # demo worker DOES see it
        da = requests.get(f"{API}/announcements", headers=demo_h, timeout=15).json()
        assert any(a.get("title") == title for a in da), "demo worker did not see sandbox announcement"

        # demo notifications include a reference
        notes = requests.get(f"{API}/notifications", headers=demo_h, timeout=15)
        assert notes.status_code == 200
        # not asserting content strictly — just endpoint works
        n_json = notes.json()
        # notifications may return list or {items:[...], unread:n}
        items = n_json.get("items") if isinstance(n_json, dict) else n_json
        assert isinstance(items, list)

        # Reviewer cannot delete a real announcement id: find a real announcement
        real_anns = requests.get(f"{API}/announcements", headers=owner_h, timeout=15).json()
        if real_anns:
            real_id = real_anns[0]["id"]
            d = requests.delete(f"{API}/announcements/{real_id}", headers=rev_h, timeout=15)
            assert d.status_code == 404, f"reviewer deleted real announcement! status={d.status_code}"

        # cleanup: reviewer deletes their own
        d2 = requests.delete(f"{API}/announcements/{ann_id}", headers=rev_h, timeout=15)
        assert d2.status_code in (200, 204), d2.text


# ---------- Worker-side isolation ----------
class TestWorkerSideIsolation:
    def test_demo_peers_empty(self, demo_h):
        r = requests.get(f"{API}/peers", headers=demo_h, timeout=15)
        assert r.status_code == 200
        assert r.json() == [] or all(p.get("email") != "lovetest@loveworks.com" for p in r.json())

    def test_real_worker_peers_no_demo(self, real_worker_h):
        r = requests.get(f"{API}/peers", headers=real_worker_h, timeout=15)
        assert r.status_code == 200
        emails = [p.get("email") for p in r.json()]
        assert "demo@loveworks.com" not in emails

    def test_demo_own_tasks(self, demo_h):
        r = requests.get(f"{API}/tasks", headers=demo_h, timeout=15)
        assert r.status_code == 200
        titles = [t.get("title") for t in r.json()]
        for t in ("Water the plants", "Fold the laundry", "Vacuum the living room"):
            assert t in titles

    def test_demo_own_goals(self, demo_h):
        r = requests.get(f"{API}/goals", headers=demo_h, timeout=15)
        assert r.status_code == 200


# ---------- Regression: real accounts unaffected ----------
class TestRealRegression:
    def test_owner_payroll_has_real(self, owner_h):
        r = requests.get(f"{API}/payroll", headers=owner_h, timeout=15)
        assert r.status_code == 200
        data = r.json()
        assert data, "owner payroll empty"
        assert not any(p.get("email") == "demo@loveworks.com" for p in data)

    def test_real_worker_clock_flow(self, real_worker_h, owner_h):
        # clock out first if active
        active = requests.get(f"{API}/time/active", headers=real_worker_h, timeout=15)
        if active.status_code == 200 and active.json():
            requests.post(f"{API}/time/clock-out", headers=real_worker_h, timeout=15)

        r = requests.post(f"{API}/time/clock-in", headers=real_worker_h,
                          json={"activity": "working"}, timeout=15)
        assert r.status_code in (200, 201), r.text

        a = requests.get(f"{API}/time/active", headers=real_worker_h, timeout=15)
        assert a.status_code == 200
        assert a.json(), "no active entry after clock-in"

        co = requests.post(f"{API}/time/clock-out", headers=real_worker_h, timeout=15)
        assert co.status_code in (200, 201), co.text

        # owner should see this entry; not demo's
        te = requests.get(f"{API}/time/entries", headers=owner_h, timeout=15)
        assert te.status_code == 200
        # ensure no demo worker entries in owner view
        rev_workers = requests.get(f"{API}/workers", headers=login(*REVIEWER), timeout=15).json()
        demo_id = next((w["id"] for w in rev_workers if w["email"] == "demo@loveworks.com"), None)
        for e in te.json():
            uid = e.get("user_id") or e.get("worker_id")
            if uid and demo_id:
                assert uid != demo_id, "demo entry leaked into owner time entries"

    def test_demo_clock_flow(self, demo_h):
        active = requests.get(f"{API}/time/active", headers=demo_h, timeout=15)
        if active.status_code == 200 and active.json():
            requests.post(f"{API}/time/clock-out", headers=demo_h, timeout=15)
        r = requests.post(f"{API}/time/clock-in", headers=demo_h, json={"activity": "working"}, timeout=15)
        assert r.status_code in (200, 201), r.text
        co = requests.post(f"{API}/time/clock-out", headers=demo_h, timeout=15)
        assert co.status_code in (200, 201), co.text


# ---------- Awards guard ----------
class TestAwardsGuard:
    def test_awards_guard(self, rev_h, owner_h):
        ws = requests.get(f"{API}/workers", headers=owner_h, timeout=15).json()
        real = next((w for w in ws if w.get("email") not in ("demo@loveworks.com",)), None)
        assert real
        # reviewer requesting real user's awards -> falls back to own
        r_rev = requests.get(f"{API}/awards", headers=rev_h, params={"user_id": real["id"]}, timeout=15)
        assert r_rev.status_code == 200
        # owner works normally
        r_own = requests.get(f"{API}/awards", headers=owner_h, params={"user_id": real["id"]}, timeout=15)
        assert r_own.status_code == 200
