"""Shared test settings, read from backend/.env, frontend/.env and the environment (never hardcoded)."""
import os
import secrets
from pathlib import Path

from dotenv import dotenv_values

_APP = Path(__file__).resolve().parents[2]
_ENV = {**dotenv_values(_APP / "frontend" / ".env"), **dotenv_values(_APP / "backend" / ".env"), **os.environ}


def _need(key: str) -> str:
    value = _ENV.get(key)
    if not value:
        raise RuntimeError(f"{key} must be set in backend/.env or the environment to run the tests")
    return value


def _account(email_key: str, password_key: str) -> dict:
    return {"email": _need(email_key), "password": _need(password_key)}


BASE_URL = _need("REACT_APP_BACKEND_URL").rstrip("/")
API = f"{BASE_URL}/api"
MONGO_URL = _need("MONGO_URL")
DB_NAME = _need("DB_NAME")

ADMIN = _account("ADMIN_EMAIL", "ADMIN_PASSWORD")
REVIEWER = _account("REVIEWER_EMAIL", "REVIEWER_PASSWORD")
DEMO_WORKER = _account("REVIEWER_WORKER_EMAIL", "REVIEWER_WORKER_PASSWORD")
WORKER = _account("TEST_WORKER_EMAIL", "TEST_WORKER_PASSWORD")


def new_password() -> str:
    """Throwaway password for accounts a test creates."""
    return "Tt1" + secrets.token_urlsafe(12)
