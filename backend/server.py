from dotenv import load_dotenv
from pathlib import Path

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

import os
import uuid
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional, List

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
    due_at: Optional[str] = None  # ISO date or datetime
    estimated_hours: Optional[float] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    assignee_id: Optional[str] = None
    status: Optional[str] = None  # assigned | in_progress | completed
    due_at: Optional[str] = None
    estimated_hours: Optional[float] = None


class ClockInRequest(BaseModel):
    activity: Optional[str] = "working"  # working | studying | break | cleaning | workout | parenting


class ProfileUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=80)


class GoalUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=160)
    product_link: Optional[str] = Field(default=None, max_length=500)
    deadline: Optional[str] = None  # ISO date (YYYY-MM-DD) or full ISO datetime


class GoalComplete(BaseModel):
    appreciation: Optional[str] = Field(default=None, max_length=500)


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


@api_router.post("/goals")
async def create_goal(
    title: str = Query(default=None),
    product_link: Optional[str] = Query(default=None),
    deadline: Optional[str] = Query(default=None),
    file: Optional[UploadFile] = File(default=None),
    user: dict = Depends(get_current_user),
):
    # Accept multipart form OR query params; pydantic on multipart is tricky so use Form-style via query
    from fastapi import Form  # noqa: F401  (kept for clarity)
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
        "status": "open",
        "appreciation": None,
        "completed_at": None,
        "completed_by": None,
        "created_at": now_utc().isoformat(),
    }
    await db.goals.insert_one(goal)
    goal.pop("_id", None)
    return _attach_goal_image_url(goal)


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
    if user["role"] == "admin":
        owner_ids = list({g["owner_id"] for g in goals})
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
        }},
    )
    updated = await db.goals.find_one({"id": goal_id}, {"_id": 0})
    return _attach_goal_image_url(updated)


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
        "estimated_hours": float(req.estimated_hours) if req.estimated_hours is not None else None,
    }
    await db.tasks.insert_one(task)
    task.pop("_id", None)
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
        if req.estimated_hours is not None:
            update["estimated_hours"] = float(req.estimated_hours) if req.estimated_hours else None
    if not update:
        raise HTTPException(status_code=400, detail="No fields to update")
    await db.tasks.update_one({"id": task_id}, {"$set": update})
    updated = await db.tasks.find_one({"id": task_id}, {"_id": 0})
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
    result = []
    for w in workers:
        tasks_done = await db.tasks.find({"assignee_id": w["id"], "status": "completed"}, {"_id": 0}).to_list(1000)
        task_earnings = sum(float(t.get("price", 0)) for t in tasks_done)
        time_entries = await db.time_entries.find(
            {"user_id": w["id"], "clock_out": {"$ne": None}}, {"_id": 0}
        ).to_list(2000)
        total_seconds = sum(int(e.get("duration_seconds", 0)) for e in time_entries)
        active = await db.time_entries.find_one({"user_id": w["id"], "clock_out": None}, {"_id": 0})
        result.append({
            "worker": serialize_user(w),
            "tasks_completed": len(tasks_done),
            "tasks_earnings": round(task_earnings, 2),
            "total_seconds": total_seconds,
            "total_hours": round(total_seconds / 3600.0, 2),
            "currently_clocked_in": bool(active),
        })
    return result


# --- Health ---
@api_router.get("/")
async def root():
    return {"message": "ClockWork API", "ok": True}


# --- App setup ---
app.include_router(api_router)

frontend_url = os.environ.get("FRONTEND_URL", "http://localhost:3000")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[frontend_url],
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
