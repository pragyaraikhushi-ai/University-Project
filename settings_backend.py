"""
Women Safety App — Settings Backend
=====================================
FastAPI service backing the SettingsScreen.

Endpoints
---------
  GET  /api/settings              — Get all app settings for a user
  PUT  /api/settings              — Update one or more settings
  GET  /api/profile               — Get the user's public profile
  PUT  /api/profile               — Update display name or avatar colour
  POST /api/settings/reset        — Reset all settings to defaults
  GET  /health                    — Liveness probe

Settings schema (all booleans unless noted)
-------------------------------------------
  notifications        : bool   — Receive safety push-alerts
  auto_alert           : bool   — Auto-alert on distress detection
  background_tracking  : bool   — Track GPS in background
  night_mode           : bool   — Reduced brightness mode
  biometric            : bool   — Fingerprint/Face unlock
  alert_frequency      : str    — "Every 1 min" | "Every 5 min" | "Every 15 min"
  language             : str    — ISO 639-1 code, default "en"
  emergency_message    : str    — Custom SOS message (max 160 chars)

Profile schema
--------------
  display_name  : str  — Shown in home screen greeting
  avatar_color  : str  — Hex colour for avatar circle
  email         : str  — Read-only (set at registration)

Run
---
  uvicorn settings_backend:app --reload --port 8004
"""

from __future__ import annotations

import re
from typing import Optional

from fastapi import FastAPI, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="Women Safety — Settings API",
    description="User preferences and profile management for the Women Safety app.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── In-memory stores ──────────────────────────────────────────────────────────
# { email: { ...settings } }
_SETTINGS: dict[str, dict] = {}

# { email: { display_name, avatar_color, email } }
_PROFILES: dict[str, dict] = {}

# ── Allowed values ────────────────────────────────────────────────────────────
_ALERT_FREQUENCIES = {"Every 1 min", "Every 5 min", "Every 15 min"}
_LANGUAGES         = {"en", "hi", "ta", "te", "bn", "mr", "gu", "kn", "ml", "ur", "pa"}

_DEFAULT_SETTINGS = {
    "notifications":       True,
    "auto_alert":          True,
    "background_tracking": True,
    "night_mode":          False,
    "biometric":           True,
    "alert_frequency":     "Every 5 min",
    "language":            "en",
    "emergency_message":   "SOS! I am in danger. Please help me immediately.",
}

_HEX_COLOR_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")
_NAME_RE       = re.compile(r"^[A-Za-z\u00C0-\u024F' \-]{2,60}$")


def _get_settings(email: str) -> dict:
    if email not in _SETTINGS:
        _SETTINGS[email] = dict(_DEFAULT_SETTINGS)
    return _SETTINGS[email]


def _get_profile(email: str) -> dict:
    if email not in _PROFILES:
        # Derive display name from email prefix
        name = email.split("@")[0].replace(".", " ").replace("_", " ").title()
        _PROFILES[email] = {
            "display_name": name,
            "avatar_color": "#4CAF50",
            "email":        email,
        }
    return _PROFILES[email]


# ── Pydantic models ───────────────────────────────────────────────────────────

class SettingsUpdate(BaseModel):
    notifications:       Optional[bool]  = None
    auto_alert:          Optional[bool]  = None
    background_tracking: Optional[bool]  = None
    night_mode:          Optional[bool]  = None
    biometric:           Optional[bool]  = None
    alert_frequency:     Optional[str]   = None
    language:            Optional[str]   = None
    emergency_message:   Optional[str]   = None

    @field_validator("alert_frequency")
    @classmethod
    def v_frequency(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in _ALERT_FREQUENCIES:
            raise ValueError(f"alert_frequency must be one of: {sorted(_ALERT_FREQUENCIES)}")
        return v

    @field_validator("language")
    @classmethod
    def v_language(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in _LANGUAGES:
            raise ValueError(f"Unsupported language code '{v}'.")
        return v

    @field_validator("emergency_message")
    @classmethod
    def v_message(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if len(v) < 5:
                raise ValueError("Emergency message must be at least 5 characters.")
            if len(v) > 160:
                raise ValueError("Emergency message must not exceed 160 characters.")
        return v


class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_color: Optional[str] = None

    @field_validator("display_name")
    @classmethod
    def v_name(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if not _NAME_RE.match(v):
                raise ValueError(
                    "Display name must be 2–60 characters and contain only letters, spaces, hyphens, and apostrophes."
                )
        return v

    @field_validator("avatar_color")
    @classmethod
    def v_color(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not _HEX_COLOR_RE.match(v):
            raise ValueError("avatar_color must be a 6-digit hex color code (e.g. #4CAF50).")
        return v


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Meta"])
async def health():
    return JSONResponse({
        "status": "ok",
        "users_with_settings": len(_SETTINGS),
    })


@app.get("/api/settings", tags=["Settings"])
async def get_settings(x_user_email: str = Header(...)):
    """Return all app settings for the authenticated user."""
    email = x_user_email.lower().strip()
    return JSONResponse(_get_settings(email))


@app.put("/api/settings", tags=["Settings"])
async def update_settings(
    body: SettingsUpdate,
    x_user_email: str = Header(...),
):
    """
    Update one or more app settings.
    Only provided fields are changed; omitted fields keep their current values.
    """
    email    = x_user_email.lower().strip()
    settings = _get_settings(email)

    updates = body.model_dump(exclude_none=True)
    settings.update(updates)

    return JSONResponse({
        "message":  "Settings updated.",
        "settings": settings,
        "changed":  list(updates.keys()),
    })


@app.post("/api/settings/reset", tags=["Settings"])
async def reset_settings(x_user_email: str = Header(...)):
    """Reset all settings to their default values."""
    email           = x_user_email.lower().strip()
    _SETTINGS[email] = dict(_DEFAULT_SETTINGS)
    return JSONResponse({
        "message":  "Settings reset to defaults.",
        "settings": _SETTINGS[email],
    })


@app.get("/api/profile", tags=["Profile"])
async def get_profile(x_user_email: str = Header(...)):
    """Return the user's display profile."""
    email = x_user_email.lower().strip()
    return JSONResponse(_get_profile(email))


@app.put("/api/profile", tags=["Profile"])
async def update_profile(
    body: ProfileUpdate,
    x_user_email: str = Header(...),
):
    """Update display name and/or avatar colour."""
    email   = x_user_email.lower().strip()
    profile = _get_profile(email)

    if body.display_name is not None:
        profile["display_name"] = body.display_name
    if body.avatar_color is not None:
        profile["avatar_color"] = body.avatar_color

    return JSONResponse({
        "message": "Profile updated.",
        "profile": profile,
    })


# ── Dev runner ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("settings_backend:app", host="0.0.0.0", port=8004, reload=True)
