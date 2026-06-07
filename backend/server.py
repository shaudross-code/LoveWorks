from dotenv import load_dotenv
from pathlib import Path

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

import os
import uuid
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional, List
try:
    from zoneinfo import ZoneInfo
except ImportError:  # Python <3.9 fallback (won't hit on our base image)
    ZoneInfo = None  # type: ignore

import bcrypt
import jwt
import requests
from fastapi import FastAPI, APIRouter, HTTPException, Request, Response, Depends, UploadFile, File, Header, Query
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel, EmailStr, Field

# --- Config ---
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_MINUTES = 60 * 24  # 24h for simplicity
REFRESH_TOKEN_DAYS = 7
MAX_FAILED_ATTEMPTS = 5
LOCKOUT_MINUTES = 15

# Object storage
STORAGE_URL = "https://integrations.emergentagent.com/objstore/api/v1/storage"
APP_NAME = os.environ.get("APP_NAME", "clockwork")
MAX_AVATAR_BYTES = 3 * 1024 * 1024  # 3 MB
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}
_storage_key: Optional[str] = None

mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

app = FastAPI(title="ClockWork API")
api_router = APIRouter(prefix="/api")

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


# --- Helpers ---
def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def hash_password(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False


def get_jwt_secret() -> str:
    return os.environ["JWT_SECRET"]


def create_access_token(user_id: str, email: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "type": "access",
        "exp": now_utc() + timedelta(minutes=ACCESS_TOKEN_MINUTES),
    }
    return jwt.encode(payload, get_jwt_secret(), algorithm=JWT_ALGORITHM)


def create_refresh_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "type": "refresh",
        "exp": now_utc() + timedelta(days=REFRESH_TOKEN_DAYS),
    }
    return jwt.encode(payload, get_jwt_secret(), algorithm=JWT_ALGORITHM)


def set_auth_cookies(response: Response, access: str, refresh: str):
    response.set_cookie("access_token", access, httponly=True, secure=True,
                        samesite="none", max_age=ACCESS_TOKEN_MINUTES * 60, path="/")
    response.set_cookie("refresh_token", refresh, httponly=True, secure=True,
                        samesite="none", max_age=REFRESH_TOKEN_DAYS * 86400, path="/")


def clear_auth_cookies(response: Response):
    response.delete_cookie("access_token", path="/")
    response.delete_cookie("refresh_token", path="/")


def serialize_user(u: dict) -> dict:
    avatar_path = u.get("avatar_path")
    return {
        "id": u["id"],
        "email": u["email"],
        "name": u.get("name", ""),
        "role": u.get("role", "worker"),
        "created_at": u.get("created_at"),
        "last_seen_at": u.get("last_seen_at"),
        "avatar_path": avatar_path,
        "avatar_url": f"/api/files/{avatar_path}" if avatar_path else None,
    }


# --- Object storage helpers ---
def init_storage() -> str:
    global _storage_key
    if _storage_key:
        return _storage_key
    emergent_key = os.environ.get("EMERGENT_LLM_KEY")
    if not emergent_key:
        raise RuntimeError("EMERGENT_LLM_KEY not set")
    resp = requests.post(f"{STORAGE_URL}/init", json={"emergent_key": emergent_key}, timeout=30)
    resp.raise_for_status()
    _storage_key = resp.json()["storage_key"]
    return _storage_key


def put_object(path: str, data: bytes, content_type: str) -> dict:
    key = init_storage()
    resp = requests.put(
        f"{STORAGE_URL}/objects/{path}",
        headers={"X-Storage-Key": key, "Content-Type": content_type},
        data=data, timeout=120,
    )
    if resp.status_code == 403:
        # storage key expired, retry once
        global _storage_key
        _storage_key = None
        key = init_storage()
        resp = requests.put(
            f"{STORAGE_URL}/objects/{path}",
            headers={"X-Storage-Key": key, "Content-Type": content_type},
            data=data, timeout=120,
        )
    resp.raise_for_status()
    return resp.json()


def get_object(path: str):
    key = init_storage()
    resp = requests.get(
        f"{STORAGE_URL}/objects/{path}",
        headers={"X-Storage-Key": key}, timeout=60,
    )
    if resp.status_code == 403:
        global _storage_key
        _storage_key = None
        key = init_storage()
        resp = requests.get(
            f"{STORAGE_URL}/objects/{path}",
            headers={"X-Storage-Key": key}, timeout=60,
        )
    resp.raise_for_status()
    return resp.content, resp.headers.get("Content-Type", "application/octet-stream")



async def get_current_user(request: Request) -> dict:
    token = request.cookies.get("access_token")
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    if not token:
        # fallback: ?auth=<token> query param (used by <img> tags)
        token = request.query_params.get("auth")
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=[JWT_ALGORITHM])
        if payload.get("type") != "access":
            raise HTTPException(status_code=401, detail="Invalid token type")
        user = await db.users.find_one({"id": payload["sub"]}, {"_id": 0})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        user.pop("password_hash", None)
        # Best-effort presence touch (throttled to once per 30s per user)
        try:
            last = user.get("last_seen_at")
            should_touch = True
            if last:
                try:
                    if (now_utc() - datetime.fromisoformat(last)).total_seconds() < 30:
                        should_touch = False
                except Exception:
                    pass
            if should_touch:
                ts = now_utc().isoformat()
                await db.users.update_one({"id": user["id"]}, {"$set": {"last_seen_at": ts}})
                user["last_seen_at"] = ts
        except Exception:
            pass
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


async def require_admin(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user


# --- Models ---
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    name: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class CreateWorkerRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    name: str


class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = ""
    price: float
    assignee_id: str
    due_at: Optional[str] = None  # ISO date or datetime (one-time deadline date)
    due_time: Optional[str] = None  # "HH:MM" 24h — time-of-day cutoff
    due_day_of_week: Optional[int] = None  # 0=Mon..6=Sun (used for weekly recurring)
    estimated_hours: Optional[float] = None
    daily_hours: Optional[float] = None
    frequency: Optional[str] = "once"
    payout_schedule: Optional[str] = "per_task"


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    assignee_id: Optional[str] = None
    status: Optional[str] = None  # assigned | in_progress | completed
    due_at: Optional[str] = None
    due_time: Optional[str] = None
    due_day_of_week: Optional[int] = None
    estimated_hours: Optional[float] = None
    daily_hours: Optional[float] = None
    frequency: Optional[str] = None
    payout_schedule: Optional[str] = None


class ClockInRequest(BaseModel):
    activity: Optional[str] = "working"  # working | studying | break | cleaning | workout | parenting


class AnnouncementCreate(BaseModel):
    title: str = Field(min_length=1, max_length=140)
    body: str = Field(min_length=1, max_length=4000)
    tag: Optional[str] = "update"  # update | feature | maintenance | announcement


# --- Awards catalog ---
AWARDS_CATALOG = {
    "first_task":       {"title": "First on the Board", "description": "You completed your very first task", "icon": "sparkle"},
    "five_tasks":       {"title": "High Five",          "description": "5 tasks completed",                   "icon": "high-five"},
    "ten_tasks":        {"title": "Bronze Worker",      "description": "10 tasks completed",                  "icon": "medal-bronze"},
    "twentyfive_tasks": {"title": "Silver Worker",      "description": "25 tasks completed",                  "icon": "medal-silver"},
    "fifty_tasks":      {"title": "Gold Worker",        "description": "50 tasks completed",                  "icon": "medal-gold"},
    "hundred_tasks":    {"title": "Platinum Worker",    "description": "100 tasks completed",                 "icon": "trophy"},
    "early_bird":       {"title": "Early Bird",         "description": "Completed a task before its due time","icon": "sunrise"},
    "streak_3":         {"title": "3-Day Streak",       "description": "Clocked in 3 days in a row",          "icon": "flame"},
    "streak_7":         {"title": "Week Warrior",       "description": "Clocked in 7 days in a row",          "icon": "flame-gold"},
}
TASK_AWARD_THRESHOLDS = [
    (1,   "first_task"),
    (5,   "five_tasks"),
    (10,  "ten_tasks"),
    (25,  "twentyfive_tasks"),
    (50,  "fifty_tasks"),
    (100, "hundred_tasks"),
]


# --- Notification & award helpers ---
async def notify(user_id: str, ntype: str, title: str, body: str = "", link: Optional[str] = None, meta: Optional[dict] = None) -> dict:
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "type": ntype,
        "title": title,
        "body": body or "",
        "link": link,
        "meta": meta or {},
        "read": False,
        "created_at": now_utc().isoformat(),
    }
    await db.notifications.insert_one(doc)
    doc.pop("_id", None)
    return doc


async def grant_award(user_id: str, code: str) -> Optional[dict]:
    if code not in AWARDS_CATALOG:
        return None
    existing = await db.awards.find_one({"user_id": user_id, "code": code})
    if existing:
        return None
    info = AWARDS_CATALOG[code]
    doc = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "code": code,
        "title": info["title"],
        "description": info["description"],
        "icon": info["icon"],
        "earned_at": now_utc().isoformat(),
    }
    await db.awards.insert_one(doc)
    doc.pop("_id", None)
    await notify(
        user_id, "award",
        f"🏆 New award: {info['title']}",
        info["description"],
        link="/worker/awards",
        meta={"code": code, "icon": info["icon"]},
    )
    return doc


async def evaluate_task_count_awards(user_id: str):
    count = await db.tasks.count_documents({"assignee_id": user_id, "status": "completed"})
    for threshold, code in TASK_AWARD_THRESHOLDS:
        if count >= threshold:
            await grant_award(user_id, code)


async def evaluate_clockin_streak(user_id: str):
    """Compute distinct clock-in dates (UTC) and grant streak awards for 3, 7 consecutive days ending today."""
    entries = await db.time_entries.find({"user_id": user_id}, {"_id": 0, "clock_in": 1}).to_list(2000)
    days = set()
    for e in entries:
        try:
            days.add(datetime.fromisoformat(e["clock_in"]).date())
        except Exception:
            continue
    if not days:
        return
    today = now_utc().date()
    streak = 0
    cur = today
    while cur in days:
        streak += 1
        cur = cur - timedelta(days=1)
    if streak >= 3:
        await grant_award(user_id, "streak_3")
    if streak >= 7:
        await grant_award(user_id, "streak_7")


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=80)


class GoalUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=160)
    product_link: Optional[str] = Field(default=None, max_length=500)
    deadline: Optional[str] = None  # ISO date (YYYY-MM-DD) or full ISO datetime
    target_amount: Optional[float] = None
    period: Optional[str] = None  # daily | weekly | yearly
    allocation_percent: Optional[float] = None  # 0..100


class GoalComplete(BaseModel):
    appreciation: Optional[str] = Field(default=None, max_length=500)


class GoalReact(BaseModel):
    emoji: str = Field(min_length=1, max_length=12)


REACTION_EMOJIS = {"👍", "❤️", "🔥", "🎉", "⭐", "💪", "🙌", "💎"}


# --- Brute force ---
async def check_lockout(identifier: str):
    rec = await db.login_attempts.find_one({"identifier": identifier})
    if not rec:
        return
    if rec.get("count", 0) >= MAX_FAILED_ATTEMPTS:
        last = rec.get("last_attempt")
        if isinstance(last, str):
            last = datetime.fromisoformat(last)
        if last and (now_utc() - last) < timedelta(minutes=LOCKOUT_MINUTES):
            raise HTTPException(status_code=429, detail="Too many failed attempts. Try again later.")


async def record_failed(identifier: str):
    await db.login_attempts.update_one(
        {"identifier": identifier},
        {"$inc": {"count": 1}, "$set": {"last_attempt": now_utc().isoformat()}},
        upsert=True,
    )


async def clear_failed(identifier: str):
    await db.login_attempts.delete_one({"identifier": identifier})


# --- Auth endpoints ---
@api_router.post("/auth/login")
async def login(req: LoginRequest, request: Request, response: Response):
    email = req.email.lower().strip()
    ip = request.client.host if request.client else "unknown"
    identifier = f"{ip}:{email}"
    await check_lockout(identifier)
    user = await db.users.find_one({"email": email}, {"_id": 0})
    if not user or not verify_password(req.password, user["password_hash"]):
        await record_failed(identifier)
        raise HTTPException(status_code=401, detail="Invalid email or password")
    await clear_failed(identifier)
    access = create_access_token(user["id"], user["email"], user["role"])
    refresh = create_refresh_token(user["id"])
    set_auth_cookies(response, access, refresh)
    return {"user": serialize_user(user), "access_token": access, "token_type": "bearer"}


@api_router.post("/auth/logout")
async def logout(response: Response, user: dict = Depends(get_current_user)):
    clear_auth_cookies(response)
    return {"ok": True}


@api_router.get("/auth/me")
async def me(user: dict = Depends(get_current_user)):
    return serialize_user(user)


@api_router.post("/auth/refresh")
async def refresh_token_endpoint(request: Request, response: Response):
    token = request.cookies.get("refresh_token")
    if not token:
        raise HTTPException(status_code=401, detail="No refresh token")
    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=[JWT_ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        user = await db.users.find_one({"id": payload["sub"]}, {"_id": 0})
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        access = create_access_token(user["id"], user["email"], user["role"])
        response.set_cookie("access_token", access, httponly=True, secure=True,
                            samesite="none", max_age=ACCESS_TOKEN_MINUTES * 60, path="/")
        return {"access_token": access}
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")


# --- Profile (self) ---
@api_router.patch("/me/profile")
async def update_profile(req: ProfileUpdate, user: dict = Depends(get_current_user)):
    await db.users.update_one({"id": user["id"]}, {"$set": {"name": req.name.strip()}})
    updated = await db.users.find_one({"id": user["id"]}, {"_id": 0, "password_hash": 0})
    return serialize_user(updated)


@api_router.post("/me/avatar")
async def upload_avatar(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="Only JPEG, PNG, WEBP, or GIF images are allowed")
    data = await file.read()
    if len(data) == 0:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(data) > MAX_AVATAR_BYTES:
        raise HTTPException(status_code=400, detail="Image too large (max 3 MB)")
    ext_map = {"image/jpeg": "jpg", "image/jpg": "jpg", "image/png": "png", "image/webp": "webp", "image/gif": "gif"}
    ext = ext_map.get(content_type, "jpg")
    path = f"{APP_NAME}/avatars/{user['id']}/{uuid.uuid4()}.{ext}"
    try:
        result = put_object(path, data, content_type)
    except Exception as e:
        logger.exception("Avatar upload failed")
        raise HTTPException(status_code=502, detail=f"Storage error: {e}")
    stored_path = result.get("path", path)
    # soft-delete previous avatar reference if any
    old = (await db.users.find_one({"id": user["id"]}, {"_id": 0, "avatar_path": 1})) or {}
    if old.get("avatar_path"):
        await db.files.update_many({"storage_path": old["avatar_path"]}, {"$set": {"is_deleted": True}})
    await db.files.insert_one({
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "storage_path": stored_path,
        "content_type": content_type,
        "size": result.get("size", len(data)),
        "is_deleted": False,
        "created_at": now_utc().isoformat(),
    })
    await db.users.update_one({"id": user["id"]}, {"$set": {"avatar_path": stored_path}})
    updated = await db.users.find_one({"id": user["id"]}, {"_id": 0, "password_hash": 0})
    return serialize_user(updated)


@api_router.delete("/me/avatar")
async def delete_avatar(user: dict = Depends(get_current_user)):
    if user.get("avatar_path"):
        await db.files.update_many({"storage_path": user["avatar_path"]}, {"$set": {"is_deleted": True}})
    await db.users.update_one({"id": user["id"]}, {"$set": {"avatar_path": None}})
    updated = await db.users.find_one({"id": user["id"]}, {"_id": 0, "password_hash": 0})
    return serialize_user(updated)


# --- File download (auth required; supports ?auth=<token> for <img> tags) ---
@api_router.get("/files/{path:path}")
async def download_file(path: str, user: dict = Depends(get_current_user)):
    record = await db.files.find_one({"storage_path": path, "is_deleted": False})
    if not record:
        raise HTTPException(status_code=404, detail="File not found")
    try:
        data, content_type = get_object(path)
    except Exception as e:
        logger.exception("File download failed")
        raise HTTPException(status_code=502, detail=f"Storage error: {e}")
    return Response(content=data, media_type=record.get("content_type", content_type))


# --- Goals ---
def _parse_deadline(s: Optional[str]) -> Optional[str]:
    if not s:
        return None
    s = s.strip()
    if not s:
        return None
    try:
        # accept YYYY-MM-DD or full ISO
        if len(s) == 10:
            dt = datetime.fromisoformat(s).replace(tzinfo=timezone.utc)
        else:
            dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
        return dt.isoformat()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid deadline format (use YYYY-MM-DD)")


def _attach_goal_image_url(g: dict) -> dict:
    g = dict(g)
    p = g.get("image_path")
    g["image_url"] = f"/api/files/{p}" if p else None
    return g


VALID_GOAL_PERIODS = {"daily", "weekly", "monthly", "yearly"}


def _validate_goal_period(v: Optional[str]) -> Optional[str]:
    if v is None:
        return None
    s = v.lower().strip()
    if not s:
        return None
    if s not in VALID_GOAL_PERIODS:
        raise HTTPException(status_code=400, detail=f"Invalid period. Use one of: {sorted(VALID_GOAL_PERIODS)}")
    return s


def _validate_allocation(v) -> Optional[float]:
    if v is None:
        return None
    try:
        n = float(v)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="allocation_percent must be a number 0..100")
    if not (0 <= n <= 100):
        raise HTTPException(status_code=400, detail="allocation_percent must be 0..100")
    return n


@api_router.post("/goals")
async def create_goal(
    title: str = Query(default=None),
    product_link: Optional[str] = Query(default=None),
    deadline: Optional[str] = Query(default=None),
    target_amount: Optional[float] = Query(default=None),
    period: Optional[str] = Query(default=None),
    allocation_percent: Optional[float] = Query(default=None),
    file: Optional[UploadFile] = File(default=None),
    user: dict = Depends(get_current_user),
):
    if not title or not title.strip():
        raise HTTPException(status_code=400, detail="Title is required")
    image_path = None
    if file is not None:
        content_type = (file.content_type or "").lower()
        if content_type not in ALLOWED_IMAGE_TYPES:
            raise HTTPException(status_code=400, detail="Only JPEG, PNG, WEBP, or GIF images are allowed")
        data = await file.read()
        if len(data) > MAX_AVATAR_BYTES:
            raise HTTPException(status_code=400, detail="Image too large (max 3 MB)")
        if data:
            ext_map = {"image/jpeg": "jpg", "image/jpg": "jpg", "image/png": "png", "image/webp": "webp", "image/gif": "gif"}
            ext = ext_map.get(content_type, "jpg")
            path = f"{APP_NAME}/goals/{user['id']}/{uuid.uuid4()}.{ext}"
            try:
                result = put_object(path, data, content_type)
            except Exception as e:
                raise HTTPException(status_code=502, detail=f"Storage error: {e}")
            image_path = result.get("path", path)
            await db.files.insert_one({
                "id": str(uuid.uuid4()),
                "user_id": user["id"],
                "storage_path": image_path,
                "content_type": content_type,
                "size": result.get("size", len(data)),
                "is_deleted": False,
                "created_at": now_utc().isoformat(),
            })
    goal = {
        "id": str(uuid.uuid4()),
        "owner_id": user["id"],
        "title": title.strip(),
        "product_link": (product_link or "").strip() or None,
        "image_path": image_path,
        "deadline": _parse_deadline(deadline),
        "target_amount": float(target_amount) if target_amount is not None else None,
        "period": _validate_goal_period(period) or "weekly",
        "allocation_percent": _validate_allocation(allocation_percent) if allocation_percent is not None else 100.0,
        "status": "open",
        "appreciation": None,
        "completed_at": None,
        "completed_by": None,
        "created_at": now_utc().isoformat(),
    }
    await db.goals.insert_one(goal)
    goal.pop("_id", None)
    return _attach_goal_image_url(goal)


def _start_of_day(dt: datetime) -> datetime:
    return dt.replace(hour=0, minute=0, second=0, microsecond=0)


def _start_of_week(dt: datetime) -> datetime:
    sod = _start_of_day(dt)
    return sod - timedelta(days=sod.weekday())  # Monday 00:00


def _start_of_month(dt: datetime) -> datetime:
    return dt.replace(day=1, hour=0, minute=0, second=0, microsecond=0)


def _start_of_year(dt: datetime) -> datetime:
    return dt.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)


async def _earnings_buckets_for_users(user_ids: list, ref: datetime) -> dict:
    """Return {user_id: {'today': X, 'week': X, 'year': X}} sums of completed task prices."""
    if not user_ids:
        return {}
    year_start = _start_of_year(ref).isoformat()
    tasks = await db.tasks.find(
        {"assignee_id": {"$in": user_ids}, "status": "completed", "completed_at": {"$gte": year_start}},
        {"_id": 0, "assignee_id": 1, "price": 1, "completed_at": 1},
    ).to_list(50000)
    today_s = _start_of_day(ref)
    week_s = _start_of_week(ref)
    month_s = _start_of_month(ref)
    out: dict = {uid: {"today": 0.0, "week": 0.0, "month": 0.0, "year": 0.0} for uid in user_ids}
    for t in tasks:
        try:
            done = datetime.fromisoformat(t["completed_at"])
            if done.tzinfo is None:
                done = done.replace(tzinfo=timezone.utc)
        except Exception:
            continue
        price = float(t.get("price") or 0)
        rec = out.get(t["assignee_id"])
        if not rec:
            continue
        rec["year"] += price
        if done >= month_s:
            rec["month"] += price
        if done >= week_s:
            rec["week"] += price
        if done >= today_s:
            rec["today"] += price
    return out


def _attach_goal_progress(g: dict, buckets: dict) -> dict:
    alloc = float(g.get("allocation_percent") or 0) / 100.0
    earn = buckets.get(g["owner_id"]) or {"today": 0.0, "week": 0.0, "month": 0.0, "year": 0.0}
    contrib_today = round(earn["today"] * alloc, 2)
    contrib_week  = round(earn["week"]  * alloc, 2)
    contrib_month = round(earn.get("month", 0.0) * alloc, 2)
    contrib_year  = round(earn["year"]  * alloc, 2)
    period = g.get("period") or "weekly"
    contrib_period = {
        "daily": contrib_today,
        "weekly": contrib_week,
        "monthly": contrib_month,
        "yearly": contrib_year,
    }.get(period, contrib_week)
    target = g.get("target_amount")
    pct = 0.0
    if target and float(target) > 0:
        pct = round(min(100.0, (contrib_period / float(target)) * 100.0), 1)
    g = dict(g)
    g["progress"] = {
        "today": contrib_today,
        "week": contrib_week,
        "month": contrib_month,
        "year": contrib_year,
        "period_amount": contrib_period,
        "pct_of_target": pct,
    }
    return g


@api_router.get("/goals")
async def list_goals(
    user: dict = Depends(get_current_user),
    owner_id: Optional[str] = None,
):
    query: dict = {}
    if user["role"] == "worker":
        query["owner_id"] = user["id"]
    elif owner_id:
        query["owner_id"] = owner_id
    goals = await db.goals.find(query, {"_id": 0}).sort("created_at", -1).to_list(2000)
    goals = [_attach_goal_image_url(g) for g in goals]

    owner_ids = list({g["owner_id"] for g in goals})
    buckets = await _earnings_buckets_for_users(owner_ids, now_utc())
    goals = [_attach_goal_progress(g, buckets) for g in goals]

    if user["role"] == "admin":
        owners = await db.users.find({"id": {"$in": owner_ids}}, {"_id": 0, "password_hash": 0}).to_list(1000)
        omap = {o["id"]: serialize_user(o) for o in owners}
        for g in goals:
            g["owner"] = omap.get(g["owner_id"])
    return goals


@api_router.patch("/goals/{goal_id}")
async def update_goal(goal_id: str, req: GoalUpdate, user: dict = Depends(get_current_user)):
    goal = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if user["role"] == "worker" and goal["owner_id"] != user["id"]:
        raise HTTPException(status_code=403, detail="Not your goal")
    update: dict = {}
    if req.title is not None:
        update["title"] = req.title.strip()
    if req.product_link is not None:
        update["product_link"] = req.product_link.strip() or None
    if req.deadline is not None:
        update["deadline"] = _parse_deadline(req.deadline) if req.deadline else None
    if req.target_amount is not None:
        update["target_amount"] = float(req.target_amount) if req.target_amount else None
    if req.period is not None:
        update["period"] = _validate_goal_period(req.period)
    if req.allocation_percent is not None:
        update["allocation_percent"] = _validate_allocation(req.allocation_percent)
    if not update:
        raise HTTPException(status_code=400, detail="No fields to update")
    await db.goals.update_one({"id": goal_id}, {"$set": update})
    updated = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    return _attach_goal_image_url(updated)


@api_router.post("/goals/{goal_id}/complete")
async def complete_goal(goal_id: str, req: GoalComplete, admin: dict = Depends(require_admin)):
    goal = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    await db.goals.update_one(
        {"id": goal_id},
        {"$set": {
            "status": "completed",
            "appreciation": (req.appreciation or "").strip() or None,
            "completed_at": now_utc().isoformat(),
            "completed_by": admin["id"],
            "acknowledged_at": None,
        }},
    )
    # Notify worker
    await notify(
        goal["owner_id"], "goal_completed",
        f"🎉 Goal achieved: {goal.get('title','')}",
        (req.appreciation or "Your admin just celebrated this goal."),
        link="/worker",
        meta={"goal_id": goal_id},
    )
    updated = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    return _attach_goal_image_url(updated)


@api_router.post("/goals/{goal_id}/react")
async def react_to_goal(goal_id: str, req: GoalReact, user: dict = Depends(get_current_user)):
    emoji = req.emoji.strip()
    if emoji not in REACTION_EMOJIS:
        raise HTTPException(status_code=400, detail=f"Use one of: {sorted(REACTION_EMOJIS)}")
    goal = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    reactions = list(goal.get("reactions") or [])
    existing_idx = next(
        (i for i, r in enumerate(reactions) if r.get("by_id") == user["id"] and r.get("emoji") == emoji),
        None,
    )
    if existing_idx is not None:
        # toggle off
        reactions.pop(existing_idx)
    else:
        reactions.append({
            "emoji": emoji,
            "by_id": user["id"],
            "by_name": user.get("name") or user["email"],
            "at": now_utc().isoformat(),
        })
        # notify the goal owner (only if reactor is not the owner)
        if user["id"] != goal["owner_id"]:
            await notify(
                goal["owner_id"], "goal_reaction",
                f"{emoji} {user.get('name') or 'Admin'} reacted",
                f'On your goal "{goal.get("title","")}"',
                link="/worker",
                meta={"goal_id": goal_id, "emoji": emoji},
            )
    await db.goals.update_one({"id": goal_id}, {"$set": {"reactions": reactions}})
    updated = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    return _attach_goal_image_url(updated)


@api_router.post("/goals/{goal_id}/acknowledge")
async def acknowledge_goal(goal_id: str, user: dict = Depends(get_current_user)):
    goal = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if goal["owner_id"] != user["id"]:
        raise HTTPException(status_code=403, detail="Not your goal")
    await db.goals.update_one({"id": goal_id}, {"$set": {"acknowledged_at": now_utc().isoformat()}})
    return {"ok": True}


@api_router.post("/goals/{goal_id}/reopen")
async def reopen_goal(goal_id: str, admin: dict = Depends(require_admin)):
    goal = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    await db.goals.update_one(
        {"id": goal_id},
        {"$set": {"status": "open", "completed_at": None, "completed_by": None, "appreciation": None}},
    )
    updated = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    return _attach_goal_image_url(updated)


@api_router.delete("/goals/{goal_id}")
async def delete_goal(goal_id: str, user: dict = Depends(get_current_user)):
    goal = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if user["role"] == "worker" and goal["owner_id"] != user["id"]:
        raise HTTPException(status_code=403, detail="Not your goal")
    if goal.get("image_path"):
        await db.files.update_many({"storage_path": goal["image_path"]}, {"$set": {"is_deleted": True}})
    await db.goals.delete_one({"id": goal_id})
    return {"ok": True}




# --- Workers (admin) ---
@api_router.post("/workers")
async def create_worker(req: CreateWorkerRequest, admin: dict = Depends(require_admin)):
    email = req.email.lower().strip()
    if await db.users.find_one({"email": email}):
        raise HTTPException(status_code=400, detail="Email already in use")
    user_doc = {
        "id": str(uuid.uuid4()),
        "email": email,
        "password_hash": hash_password(req.password),
        "name": req.name,
        "role": "worker",
        "created_at": now_utc().isoformat(),
    }
    await db.users.insert_one(user_doc)
    return serialize_user(user_doc)


@api_router.get("/workers")
async def list_workers(admin: dict = Depends(require_admin)):
    workers = await db.users.find({"role": "worker"}, {"_id": 0, "password_hash": 0}).to_list(1000)
    return [serialize_user(w) for w in workers]


@api_router.delete("/workers/{worker_id}")
async def delete_worker(worker_id: str, admin: dict = Depends(require_admin)):
    res = await db.users.delete_one({"id": worker_id, "role": "worker"})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Worker not found")
    await db.tasks.delete_many({"assignee_id": worker_id})
    await db.time_entries.delete_many({"user_id": worker_id})
    return {"ok": True}


# --- Tasks ---
VALID_ACTIVITIES = {"working", "studying", "break", "cleaning", "workout", "parenting"}
VALID_FREQUENCIES = {"once", "daily", "weekly", "monthly"}
VALID_PAYOUTS = {"per_task", "daily", "weekly", "monthly"}


def _validate_frequency(v: Optional[str]) -> Optional[str]:
    if v is None:
        return None
    v = v.lower().strip()
    if v not in VALID_FREQUENCIES:
        raise HTTPException(status_code=400, detail=f"Invalid frequency. Use one of: {sorted(VALID_FREQUENCIES)}")
    return v


def _validate_payout(v: Optional[str]) -> Optional[str]:
    if v is None:
        return None
    v = v.lower().strip()
    if v not in VALID_PAYOUTS:
        raise HTTPException(status_code=400, detail=f"Invalid payout_schedule. Use one of: {sorted(VALID_PAYOUTS)}")
    return v


def _validate_due_time(v: Optional[str]) -> Optional[str]:
    """Accepts 'HH:MM' (24h) or 'HH:MM:SS' — returns 'HH:MM' normalized, or None."""
    if v is None:
        return None
    s = v.strip()
    if not s:
        return None
    parts = s.split(":")
    if len(parts) < 2 or len(parts) > 3:
        raise HTTPException(status_code=400, detail="due_time must be HH:MM (24h)")
    try:
        h = int(parts[0])
        m = int(parts[1])
    except ValueError:
        raise HTTPException(status_code=400, detail="due_time must be HH:MM (24h)")
    if not (0 <= h <= 23 and 0 <= m <= 59):
        raise HTTPException(status_code=400, detail="due_time must be HH:MM (24h)")
    return f"{h:02d}:{m:02d}"


def _validate_dow(v):
    if v is None:
        return None
    try:
        n = int(v)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="due_day_of_week must be 0..6 (0=Mon)")
    if not (0 <= n <= 6):
        raise HTTPException(status_code=400, detail="due_day_of_week must be 0..6 (0=Mon)")
    return n


@api_router.post("/tasks")
async def create_task(req: TaskCreate, admin: dict = Depends(require_admin)):
    worker = await db.users.find_one({"id": req.assignee_id, "role": "worker"})
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")
    task = {
        "id": str(uuid.uuid4()),
        "title": req.title,
        "description": req.description or "",
        "price": float(req.price),
        "assignee_id": req.assignee_id,
        "status": "assigned",
        "created_by": admin["id"],
        "created_at": now_utc().isoformat(),
        "completed_at": None,
        "due_at": _parse_deadline(req.due_at),
        "due_time": _validate_due_time(req.due_time),
        "due_day_of_week": _validate_dow(req.due_day_of_week),
        "estimated_hours": float(req.estimated_hours) if req.estimated_hours is not None else None,
        "daily_hours": float(req.daily_hours) if req.daily_hours is not None else None,
        "frequency": _validate_frequency(req.frequency) or "once",
        "payout_schedule": _validate_payout(req.payout_schedule) or "per_task",
    }
    await db.tasks.insert_one(task)
    task.pop("_id", None)
    # Notify the assignee about the new task
    when_parts = []
    if task.get("due_at"):
        try:
            when_parts.append(datetime.fromisoformat(task["due_at"]).strftime("%b %d"))
        except Exception:
            pass
    if task.get("due_day_of_week") is not None:
        when_parts.append(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][task["due_day_of_week"]])
    if task.get("due_time"):
        when_parts.append(f"by {task['due_time']}")
    when_str = " · ".join(when_parts) if when_parts else "no deadline"
    await notify(
        req.assignee_id, "task_assigned",
        f"New task: {task['title']}",
        f"${float(task['price']):.2f} · {when_str}",
        link="/worker",
        meta={"task_id": task["id"]},
    )
    return task


@api_router.get("/tasks")
async def list_tasks(user: dict = Depends(get_current_user), assignee_id: Optional[str] = None):
    query: dict = {}
    if user["role"] == "worker":
        query["assignee_id"] = user["id"]
    elif assignee_id:
        query["assignee_id"] = assignee_id
    tasks = await db.tasks.find(query, {"_id": 0}).sort("created_at", -1).to_list(1000)
    # attach assignee_name for admin convenience
    if user["role"] == "admin":
        worker_ids = list({t["assignee_id"] for t in tasks})
        workers = await db.users.find({"id": {"$in": worker_ids}}, {"_id": 0, "id": 1, "name": 1, "email": 1}).to_list(1000)
        wmap = {w["id"]: w for w in workers}
        for t in tasks:
            w = wmap.get(t["assignee_id"], {})
            t["assignee_name"] = w.get("name", "Unknown")
            t["assignee_email"] = w.get("email", "")
    return tasks


@api_router.patch("/tasks/{task_id}")
async def update_task(task_id: str, req: TaskUpdate, user: dict = Depends(get_current_user)):
    task = await db.tasks.find_one({"id": task_id}, {"_id": 0})
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    # workers may only update status of their own tasks
    update: dict = {}
    if user["role"] == "worker":
        if task["assignee_id"] != user["id"]:
            raise HTTPException(status_code=403, detail="Not your task")
        if req.status not in ("in_progress", "completed", "assigned"):
            raise HTTPException(status_code=400, detail="Workers may only update status")
        update["status"] = req.status
        if req.status == "completed":
            update["completed_at"] = now_utc().isoformat()
    else:
        if req.title is not None:
            update["title"] = req.title
        if req.description is not None:
            update["description"] = req.description
        if req.price is not None:
            update["price"] = float(req.price)
        if req.assignee_id is not None:
            update["assignee_id"] = req.assignee_id
        if req.status is not None:
            update["status"] = req.status
            if req.status == "completed":
                update["completed_at"] = now_utc().isoformat()
        if req.due_at is not None:
            update["due_at"] = _parse_deadline(req.due_at) if req.due_at else None
        if req.due_time is not None:
            update["due_time"] = _validate_due_time(req.due_time) if req.due_time else None
        if req.due_day_of_week is not None:
            # explicit empty string handling: an empty/-1 means clear
            update["due_day_of_week"] = _validate_dow(req.due_day_of_week) if req.due_day_of_week != -1 else None
        if req.estimated_hours is not None:
            update["estimated_hours"] = float(req.estimated_hours) if req.estimated_hours else None
        if req.daily_hours is not None:
            update["daily_hours"] = float(req.daily_hours) if req.daily_hours else None
        if req.frequency is not None:
            update["frequency"] = _validate_frequency(req.frequency)
        if req.payout_schedule is not None:
            update["payout_schedule"] = _validate_payout(req.payout_schedule)
    if not update:
        raise HTTPException(status_code=400, detail="No fields to update")
    await db.tasks.update_one({"id": task_id}, {"$set": update})
    updated = await db.tasks.find_one({"id": task_id}, {"_id": 0})
    # Award + notify on task completion
    if update.get("status") == "completed" and task.get("status") != "completed":
        owner_id = updated["assignee_id"]
        # Early-bird award if completed before due_time today
        if updated.get("due_time"):
            try:
                hh, mm = [int(x) for x in updated["due_time"].split(":")[:2]]
                now = now_utc()
                deadline_today = now.replace(hour=hh, minute=mm, second=0, microsecond=0)
                if now <= deadline_today:
                    await grant_award(owner_id, "early_bird")
            except Exception:
                pass
        await evaluate_task_count_awards(owner_id)
    return updated


@api_router.delete("/tasks/{task_id}")
async def delete_task(task_id: str, admin: dict = Depends(require_admin)):
    res = await db.tasks.delete_one({"id": task_id})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"ok": True}


# --- Time entries / Clock ---
@api_router.post("/time/clock-in")
async def clock_in(req: ClockInRequest = ClockInRequest(), user: dict = Depends(get_current_user)):
    activity = (req.activity or "working").lower()
    if activity not in VALID_ACTIVITIES:
        raise HTTPException(status_code=400, detail=f"Invalid activity. Use one of: {sorted(VALID_ACTIVITIES)}")
    active = await db.time_entries.find_one({"user_id": user["id"], "clock_out": None}, {"_id": 0})
    if active:
        raise HTTPException(status_code=400, detail="You are already clocked in")
    entry = {
        "id": str(uuid.uuid4()),
        "user_id": user["id"],
        "clock_in": now_utc().isoformat(),
        "clock_out": None,
        "duration_seconds": 0,
        "activity": activity,
    }
    await db.time_entries.insert_one(entry)
    entry.pop("_id", None)
    # Evaluate streak awards
    await evaluate_clockin_streak(user["id"])
    return entry


@api_router.post("/time/clock-out")
async def clock_out(user: dict = Depends(get_current_user)):
    active = await db.time_entries.find_one({"user_id": user["id"], "clock_out": None}, {"_id": 0})
    if not active:
        raise HTTPException(status_code=400, detail="You are not clocked in")
    clock_in_dt = datetime.fromisoformat(active["clock_in"])
    out_dt = now_utc()
    duration = int((out_dt - clock_in_dt).total_seconds())
    await db.time_entries.update_one(
        {"id": active["id"]},
        {"$set": {"clock_out": out_dt.isoformat(), "duration_seconds": duration}},
    )
    return {**active, "clock_out": out_dt.isoformat(), "duration_seconds": duration}


@api_router.get("/time/active")
async def active_entry(user: dict = Depends(get_current_user)):
    active = await db.time_entries.find_one({"user_id": user["id"], "clock_out": None}, {"_id": 0})
    return active or {}


@api_router.get("/time/entries")
async def list_time_entries(user: dict = Depends(get_current_user), user_id: Optional[str] = None):
    query: dict = {}
    if user["role"] == "worker":
        query["user_id"] = user["id"]
    elif user_id:
        query["user_id"] = user_id
    entries = await db.time_entries.find(query, {"_id": 0}).sort("clock_in", -1).to_list(2000)
    return entries


# --- Payroll ---
@api_router.get("/payroll")
async def payroll(admin: dict = Depends(require_admin)):
    workers = await db.users.find({"role": "worker"}, {"_id": 0, "password_hash": 0}).to_list(1000)
    worker_ids = [w["id"] for w in workers]
    if not worker_ids:
        return []

    # Batch fetch: completed tasks + all time entries (only the fields we need)
    tasks_done = await db.tasks.find(
        {"assignee_id": {"$in": worker_ids}, "status": "completed"},
        {"_id": 0, "assignee_id": 1, "price": 1},
    ).to_list(10000)
    time_entries = await db.time_entries.find(
        {"user_id": {"$in": worker_ids}},
        {"_id": 0, "user_id": 1, "clock_out": 1, "duration_seconds": 1},
    ).to_list(20000)

    earnings_by_worker: dict[str, float] = {}
    completed_count_by_worker: dict[str, int] = {}
    for t in tasks_done:
        wid = t["assignee_id"]
        earnings_by_worker[wid] = earnings_by_worker.get(wid, 0.0) + float(t.get("price", 0))
        completed_count_by_worker[wid] = completed_count_by_worker.get(wid, 0) + 1

    seconds_by_worker: dict[str, int] = {}
    active_by_worker: dict[str, bool] = {}
    for e in time_entries:
        wid = e["user_id"]
        if e.get("clock_out"):
            seconds_by_worker[wid] = seconds_by_worker.get(wid, 0) + int(e.get("duration_seconds", 0))
        else:
            active_by_worker[wid] = True

    return [
        {
            "worker": serialize_user(w),
            "tasks_completed": completed_count_by_worker.get(w["id"], 0),
            "tasks_earnings": round(earnings_by_worker.get(w["id"], 0.0), 2),
            "total_seconds": seconds_by_worker.get(w["id"], 0),
            "total_hours": round(seconds_by_worker.get(w["id"], 0) / 3600.0, 2),
            "currently_clocked_in": active_by_worker.get(w["id"], False),
        }
        for w in workers
    ]


# --- Admin live worker monitor ---
PRESENCE_WINDOW_SECONDS = 120  # active in last 2 min => "online"
WORKDAYS_PER_WEEK = 5


@api_router.get("/admin/worker-status")
async def admin_worker_status(admin: dict = Depends(require_admin)):
    workers = await db.users.find({"role": "worker"}, {"_id": 0, "password_hash": 0}).to_list(1000)
    if not workers:
        return []
    worker_ids = [w["id"] for w in workers]
    now = now_utc()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=today_start.weekday())  # Monday 00:00 UTC

    entries_week = await db.time_entries.find(
        {"user_id": {"$in": worker_ids}, "clock_in": {"$gte": week_start.isoformat()}},
        {"_id": 0},
    ).to_list(10000)
    leftover_active = await db.time_entries.find(
        {"user_id": {"$in": worker_ids}, "clock_out": None, "clock_in": {"$lt": week_start.isoformat()}},
        {"_id": 0},
    ).to_list(1000)
    active_map: dict = {}
    for e in entries_week:
        if e.get("clock_out") is None:
            active_map[e["user_id"]] = e
    for e in leftover_active:
        active_map.setdefault(e["user_id"], e)

    open_tasks = await db.tasks.find(
        {"assignee_id": {"$in": worker_ids}, "status": {"$ne": "completed"}},
        {"_id": 0, "assignee_id": 1, "daily_hours": 1, "estimated_hours": 1, "frequency": 1, "title": 1, "status": 1, "price": 1},
    ).to_list(10000)

    # Completed this week, for per-weekday counts
    completed_week = await db.tasks.find(
        {"assignee_id": {"$in": worker_ids}, "status": "completed", "completed_at": {"$gte": week_start.isoformat()}},
        {"_id": 0, "assignee_id": 1, "completed_at": 1, "title": 1, "price": 1},
    ).to_list(10000)
    completions_by_day: dict = {wid: [{"count": 0, "earned": 0.0, "hours": 0.0, "titles": []} for _ in range(7)] for wid in worker_ids}
    for t in completed_week:
        try:
            done = datetime.fromisoformat(t["completed_at"])
            if done.tzinfo is None:
                done = done.replace(tzinfo=timezone.utc)
        except Exception:
            continue
        wid = t.get("assignee_id")
        if wid not in completions_by_day:
            continue
        dow = done.weekday()
        slot = completions_by_day[wid][dow]
        slot["count"] += 1
        slot["earned"] += float(t.get("price") or 0)
        if len(slot["titles"]) < 5:
            slot["titles"].append(t.get("title", ""))

    # Hours clocked per weekday this week
    for e in entries_week:
        wid = e.get("user_id")
        if wid not in completions_by_day:
            continue
        try:
            in_dt = datetime.fromisoformat(e["clock_in"])
        except Exception:
            continue
        if e.get("clock_out"):
            try:
                out_dt = datetime.fromisoformat(e["clock_out"])
            except Exception:
                out_dt = now
        else:
            out_dt = now
        seg_start = max(in_dt, week_start)
        cur = seg_start
        # split across day boundaries so hours land on the right weekday
        while cur < out_dt:
            day_end = (cur + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
            chunk_end = min(out_dt, day_end)
            secs = max(0, int((chunk_end - cur).total_seconds()))
            dow = cur.weekday()
            if 0 <= dow <= 6:
                completions_by_day[wid][dow]["hours"] += secs / 3600.0
            cur = chunk_end

    # Compute streak (consecutive days ending today w/ any completion)
    def _compute_streak(slots: list) -> int:
        today_idx = now.weekday()  # 0=Mon..6=Sun
        s = 0
        for k in range(today_idx + 1):
            if slots[today_idx - k]["count"] > 0:
                s += 1
            else:
                break
        return s

    results = []
    for w in workers:
        wid = w["id"]
        today_seconds = 0
        week_seconds = 0
        for e in entries_week:
            if e["user_id"] != wid:
                continue
            try:
                in_dt = datetime.fromisoformat(e["clock_in"])
            except Exception:
                continue
            if e.get("clock_out"):
                try:
                    out_dt = datetime.fromisoformat(e["clock_out"])
                except Exception:
                    out_dt = now
            else:
                out_dt = now
            seg_start = max(in_dt, week_start)
            seg_end = max(seg_start, out_dt)
            week_seconds += int((seg_end - seg_start).total_seconds())
            t_seg_start = max(in_dt, today_start)
            if seg_end > t_seg_start:
                today_seconds += int((seg_end - t_seg_start).total_seconds())
        # Leftover active that started before this week
        le = active_map.get(wid)
        if le:
            try:
                le_in = datetime.fromisoformat(le["clock_in"])
                if le_in < week_start:
                    week_seconds += int((now - week_start).total_seconds())
                    today_seconds += int((now - today_start).total_seconds())
            except Exception:
                pass

        # Required hours + potential earnings
        daily_required = 0.0
        weekly_required = 0.0
        open_count = 0
        potential_weekly = 0.0
        potential_monthly = 0.0
        WORKDAYS_PER_MONTH = 20
        for t in open_tasks:
            if t["assignee_id"] != wid:
                continue
            open_count += 1
            dh = float(t.get("daily_hours") or 0)
            est = float(t.get("estimated_hours") or 0)
            freq = t.get("frequency") or "once"
            price = float(t.get("price") or 0)
            # Potential earnings rollup
            if freq == "daily":
                potential_weekly  += price * WORKDAYS_PER_WEEK
                potential_monthly += price * WORKDAYS_PER_MONTH
            elif freq == "weekly":
                potential_weekly  += price
                potential_monthly += price * 4
            elif freq == "monthly":
                potential_weekly  += price / 4.0
                potential_monthly += price
            else:  # once
                potential_weekly  += price
                potential_monthly += price
            # Required hours (existing logic)
            if dh > 0:
                if freq == "daily":
                    daily_required += dh
                    weekly_required += dh * WORKDAYS_PER_WEEK
                elif freq == "weekly":
                    daily_required += dh
                    weekly_required += dh * WORKDAYS_PER_WEEK
                elif freq == "monthly":
                    daily_required += dh / 4.0
                    weekly_required += dh * WORKDAYS_PER_WEEK
                else:  # once
                    daily_required += dh
                    weekly_required += dh * WORKDAYS_PER_WEEK
            elif est > 0 and freq in ("weekly", "once"):
                weekly_required += est

        last_seen = w.get("last_seen_at")
        online = False
        if last_seen:
            try:
                online = (now - datetime.fromisoformat(last_seen)).total_seconds() < PRESENCE_WINDOW_SECONDS
            except Exception:
                pass
        active = active_map.get(wid)
        today_hours = today_seconds / 3600.0
        week_hours = week_seconds / 3600.0
        results.append({
            "worker": serialize_user(w),
            "online": online,
            "last_seen_at": last_seen,
            "currently_clocked_in": bool(active),
            "active_activity": active.get("activity") if active else None,
            "active_clock_in_at": active.get("clock_in") if active else None,
            "today_worked_seconds": today_seconds,
            "week_worked_seconds": week_seconds,
            "today_worked_hours": round(today_hours, 2),
            "week_worked_hours": round(week_hours, 2),
            "daily_required_hours": round(daily_required, 2),
            "weekly_required_hours": round(weekly_required, 2),
            "today_left_hours": round(max(0.0, daily_required - today_hours), 2),
            "week_left_hours": round(max(0.0, weekly_required - week_hours), 2),
            "open_tasks_count": open_count,
            "potential_weekly": round(potential_weekly, 2),
            "potential_monthly": round(potential_monthly, 2),
            "streak_days": _compute_streak(completions_by_day.get(wid, [])),
            "completions_by_day": [
                {"day": d, "count": s["count"], "earned": round(s["earned"], 2), "hours": round(s["hours"], 2), "titles": s["titles"]}
                for d, s in zip(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], completions_by_day.get(wid, []))
            ],
        })
    # sort: online first, then currently_clocked_in, then by name
    results.sort(key=lambda r: (not r["online"], not r["currently_clocked_in"], (r["worker"]["name"] or "").lower()))
    return results


@api_router.get("/me/weekly-activity")
async def my_weekly_activity(user: dict = Depends(get_current_user)):
    """Returns the requesting user's own weekly completion strip + streak."""
    now = now_utc()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=today_start.weekday())
    uid = user["id"]

    completed = await db.tasks.find(
        {"assignee_id": uid, "status": "completed", "completed_at": {"$gte": week_start.isoformat()}},
        {"_id": 0, "completed_at": 1, "title": 1, "price": 1},
    ).to_list(2000)
    entries = await db.time_entries.find(
        {"user_id": uid, "clock_in": {"$gte": week_start.isoformat()}},
        {"_id": 0, "clock_in": 1, "clock_out": 1},
    ).to_list(2000)
    slots = [{"count": 0, "earned": 0.0, "hours": 0.0, "titles": []} for _ in range(7)]
    for t in completed:
        try:
            done = datetime.fromisoformat(t["completed_at"])
            if done.tzinfo is None:
                done = done.replace(tzinfo=timezone.utc)
        except Exception:
            continue
        slot = slots[done.weekday()]
        slot["count"] += 1
        slot["earned"] += float(t.get("price") or 0)
        if len(slot["titles"]) < 5:
            slot["titles"].append(t.get("title", ""))
    for e in entries:
        try:
            in_dt = datetime.fromisoformat(e["clock_in"])
        except Exception:
            continue
        if e.get("clock_out"):
            try:
                out_dt = datetime.fromisoformat(e["clock_out"])
            except Exception:
                out_dt = now
        else:
            out_dt = now
        cur = max(in_dt, week_start)
        while cur < out_dt:
            day_end = (cur + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
            chunk_end = min(out_dt, day_end)
            secs = max(0, int((chunk_end - cur).total_seconds()))
            dow = cur.weekday()
            if 0 <= dow <= 6:
                slots[dow]["hours"] += secs / 3600.0
            cur = chunk_end
    today_idx = now.weekday()
    streak = 0
    for k in range(today_idx + 1):
        if slots[today_idx - k]["count"] > 0:
            streak += 1
        else:
            break
    return {
        "streak_days": streak,
        "completions_by_day": [
            {"day": d, "count": s["count"], "earned": round(s["earned"], 2), "hours": round(s["hours"], 2), "titles": s["titles"]}
            for d, s in zip(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], slots)
        ],
    }


# --- Notifications ---
@api_router.get("/notifications")
async def list_notifications(user: dict = Depends(get_current_user), limit: int = 50):
    items = await db.notifications.find(
        {"user_id": user["id"]}, {"_id": 0}
    ).sort("created_at", -1).limit(min(max(limit, 1), 200)).to_list(200)
    unread = await db.notifications.count_documents({"user_id": user["id"], "read": False})
    return {"items": items, "unread": unread}


@api_router.post("/notifications/{nid}/read")
async def mark_notification_read(nid: str, user: dict = Depends(get_current_user)):
    await db.notifications.update_one(
        {"id": nid, "user_id": user["id"]},
        {"$set": {"read": True}},
    )
    return {"ok": True}


@api_router.post("/notifications/read-all")
async def mark_all_read(user: dict = Depends(get_current_user)):
    await db.notifications.update_many(
        {"user_id": user["id"], "read": False},
        {"$set": {"read": True}},
    )
    return {"ok": True}


# --- Awards ---
@api_router.get("/awards/catalog")
async def awards_catalog(user: dict = Depends(get_current_user)):
    return [{"code": code, **info} for code, info in AWARDS_CATALOG.items()]


@api_router.get("/awards")
async def list_awards(user: dict = Depends(get_current_user), user_id: Optional[str] = None):
    target = user_id if (user["role"] == "admin" and user_id) else user["id"]
    earned = await db.awards.find({"user_id": target}, {"_id": 0}).sort("earned_at", -1).to_list(500)
    earned_codes = {a["code"] for a in earned}
    catalog = []
    for code, info in AWARDS_CATALOG.items():
        match = next((a for a in earned if a["code"] == code), None)
        catalog.append({
            "code": code,
            **info,
            "earned": code in earned_codes,
            "earned_at": match["earned_at"] if match else None,
        })
    return {"earned_count": len(earned), "total": len(AWARDS_CATALOG), "items": catalog}


# --- Announcements ---
@api_router.post("/announcements")
async def create_announcement(req: AnnouncementCreate, admin: dict = Depends(require_admin)):
    tag = (req.tag or "update").lower().strip()
    if tag not in {"update", "feature", "maintenance", "announcement"}:
        tag = "update"
    doc = {
        "id": str(uuid.uuid4()),
        "title": req.title.strip(),
        "body": req.body.strip(),
        "tag": tag,
        "created_by": admin["id"],
        "created_at": now_utc().isoformat(),
    }
    await db.announcements.insert_one(doc)
    doc.pop("_id", None)
    # Fan-out a notification to every worker
    workers = await db.users.find({"role": "worker"}, {"_id": 0, "id": 1}).to_list(2000)
    icon = {"feature": "✨", "maintenance": "🛠️", "announcement": "📣", "update": "📣"}.get(tag, "📣")
    for w in workers:
        await notify(
            w["id"], "announcement",
            f"{icon} {doc['title']}",
            doc["body"][:160],
            link="/worker/announcements",
            meta={"announcement_id": doc["id"], "tag": tag},
        )
    return doc


@api_router.get("/announcements")
async def list_announcements(user: dict = Depends(get_current_user)):
    items = await db.announcements.find({}, {"_id": 0}).sort("created_at", -1).to_list(500)
    return items


@api_router.delete("/announcements/{aid}")
async def delete_announcement(aid: str, admin: dict = Depends(require_admin)):
    res = await db.announcements.delete_one({"id": aid})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Announcement not found")
    return {"ok": True}


# --- Health ---
@api_router.get("/")
async def root():
    return {"message": "ClockWork API", "ok": True}


# --- App setup ---
app.include_router(api_router)

cors_origins_env = os.environ.get("CORS_ORIGINS", "*").strip()
if cors_origins_env in ("", "*"):
    # Permissive but credentials-friendly: match localhost (dev) + emergent preview & prod domains.
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"https?://(localhost(:\d+)?|.*\.emergentagent\.com|.*\.emergent\.host)",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    origins = [o.strip() for o in cors_origins_env.split(",") if o.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


@app.on_event("startup")
async def startup():
    await db.users.create_index("email", unique=True)
    await db.users.create_index("id", unique=True)
    await db.tasks.create_index("assignee_id")
    await db.time_entries.create_index([("user_id", 1), ("clock_out", 1)])
    await db.login_attempts.create_index("identifier")
    await db.files.create_index("storage_path")
    await db.goals.create_index("owner_id")
    await db.notifications.create_index([("user_id", 1), ("read", 1), ("created_at", -1)])
    await db.awards.create_index([("user_id", 1), ("code", 1)], unique=True)
    await db.announcements.create_index("created_at")
    # init object storage
    try:
        init_storage()
        logger.info("Object storage initialized")
    except Exception as e:
        logger.error(f"Storage init failed: {e}")
    # seed admin
    admin_email = os.environ.get("ADMIN_EMAIL", "admin@example.com").lower()
    admin_password = os.environ.get("ADMIN_PASSWORD", "admin123")
    existing = await db.users.find_one({"email": admin_email})
    if not existing:
        await db.users.insert_one({
            "id": str(uuid.uuid4()),
            "email": admin_email,
            "password_hash": hash_password(admin_password),
            "name": "Administrator",
            "role": "admin",
            "created_at": now_utc().isoformat(),
        })
        logger.info(f"Seeded admin user: {admin_email}")
    elif not verify_password(admin_password, existing["password_hash"]):
        await db.users.update_one(
            {"email": admin_email},
            {"$set": {"password_hash": hash_password(admin_password)}},
        )
        logger.info(f"Updated admin password for: {admin_email}")


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
age_path")
    await db.goals.create_index("owner_id")
    await db.notifications.create_index([("user_id", 1), ("read", 1), ("created_at", -1)])
    await db.awards.create_index([("user_id", 1), ("code", 1)], unique=True)
    await db.announcements.create_index("created_at")
    # init object storage
    try:
        init_storage()
        logger.info("Object storage initialized")
    except Exception as e:
        logger.error(f"Storage init failed: {e}")
    # seed admin
    admin_email = os.environ.get("ADMIN_EMAIL", "admin@example.com").lower()
    admin_password = os.environ.get("ADMIN_PASSWORD", "admin123")
    existing = await db.users.find_one({"email": admin_email})
    if not existing:
        await db.users.insert_one({
            "id": str(uuid.uuid4()),
            "email": admin_email,
            "password_hash": hash_password(admin_password),
            "name": "Administrator",
            "role": "admin",
            "created_at": now_utc().isoformat(),
        })
        logger.info(f"Seeded admin user: {admin_email}")
    elif not verify_password(admin_password, existing["password_hash"]):
        await db.users.update_one(
            {"email": admin_email},
            {"$set": {"password_hash": hash_password(admin_password)}},
        )
        logger.info(f"Updated admin password for: {admin_email}")


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
