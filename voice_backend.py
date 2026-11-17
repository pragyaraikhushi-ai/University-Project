"""
Women Safety App — Voice Guard Backend
=======================================
FastAPI service backing the VoiceScreen.

Endpoints
---------
  GET    /api/voice/settings            — Get voice guard settings for a user
  PUT    /api/voice/settings            — Update voice guard enabled/sensitivity
  GET    /api/voice/keywords            — List trigger keywords
  POST   /api/voice/keywords            — Add a custom keyword
  DELETE /api/voice/keywords/{keyword}  — Remove a keyword
  POST   /api/voice/trigger             — Log a detected keyword event (alert or cancel)
  GET    /api/voice/logs                — Get the voice alert log (newest first)
  DELETE /api/voice/logs                — Clear all voice logs for a user
  GET    /health                        — Liveness probe

Voice Guard logic
-----------------
  When a keyword is detected on the device the Flutter app calls
  POST /api/voice/trigger  with the keyword and optional lat/lng.
  The backend:
    1. Logs the event.
    2. If voice_guard_enabled == True → returns action "sos_alert"
       (Flutter then calls POST /api/sos on contacts_backend).
    3. If disabled → returns action "log_only".

Run
---
  uvicorn voice_backend:app --reload --port 8003
"""

from __future__ import annotations

import datetime
import re
import uuid
from typing import Optional

from fastapi import FastAPI, HTTPException, Header, Path
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="Women Safety — Voice Guard API",
    description="Voice keyword management and alert-logging for the Women Safety app.",
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
# { email: { voice_guard_enabled: bool, sensitivity: str } }
_SETTINGS: dict[str, dict] = {}

# { email: [keyword_str, ...] }
_KEYWORDS: dict[str, list[str]] = {}

# { email: [ { id, timestamp, keyword, action, lat, lng } ] }
_LOGS: dict[str, list[dict]] = {}

# ── Default keywords ──────────────────────────────────────────────────────────
_DEFAULT_KEYWORDS = ["Help me", "SOS", "Emergency", "Save me"]

# ── Default voice guard settings ──────────────────────────────────────────────
_DEFAULT_SETTINGS = {
    "voice_guard_enabled": True,
    "sensitivity": "medium",   # low | medium | high
    "auto_cancel_seconds": 10, # seconds before alert auto-fires (not cancelled)
}

# ── Validation ────────────────────────────────────────────────────────────────
_KEYWORD_RE = re.compile(r"^[A-Za-z0-9 !\-']+$")


def _validate_keyword(kw: str) -> str:
    kw = kw.strip()
    if len(kw) < 2:
        raise ValueError("Keyword must be at least 2 characters.")
    if len(kw) > 40:
        raise ValueError("Keyword must not exceed 40 characters.")
    if not _KEYWORD_RE.match(kw):
        raise ValueError("Keyword may only contain letters, numbers, spaces, hyphens, apostrophes, and '!'.")
    return kw


def _get_settings(email: str) -> dict:
    if email not in _SETTINGS:
        _SETTINGS[email] = dict(_DEFAULT_SETTINGS)
    return _SETTINGS[email]


def _get_keywords(email: str) -> list[str]:
    if email not in _KEYWORDS:
        _KEYWORDS[email] = list(_DEFAULT_KEYWORDS)
    return _KEYWORDS[email]


def _get_logs(email: str) -> list[dict]:
    return _LOGS.setdefault(email, [])


# ── Pydantic models ───────────────────────────────────────────────────────────

class VoiceSettingsUpdate(BaseModel):
    voice_guard_enabled: Optional[bool]  = None
    sensitivity:         Optional[str]   = None   # low | medium | high
    auto_cancel_seconds: Optional[int]   = None   # 5-30

    @field_validator("sensitivity")
    @classmethod
    def v_sensitivity(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in {"low", "medium", "high"}:
            raise ValueError("Sensitivity must be 'low', 'medium', or 'high'.")
        return v

    @field_validator("auto_cancel_seconds")
    @classmethod
    def v_cancel(cls, v: Optional[int]) -> Optional[int]:
        if v is not None and not (5 <= v <= 30):
            raise ValueError("auto_cancel_seconds must be between 5 and 30.")
        return v


class KeywordAdd(BaseModel):
    keyword: str

    @field_validator("keyword")
    @classmethod
    def v_keyword(cls, v: str) -> str:
        return _validate_keyword(v)


class VoiceTrigger(BaseModel):
    """Posted by the Flutter app when the speech recogniser detects a keyword."""
    keyword: str
    action:  str = "alert"   # "alert" | "cancel"
    lat:     Optional[float] = None
    lng:     Optional[float] = None


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Meta"])
async def health():
    return JSONResponse({
        "status": "ok",
        "users": len(_SETTINGS),
    })


@app.get("/api/voice/settings", tags=["Voice Guard"])
async def get_voice_settings(x_user_email: str = Header(...)):
    email = x_user_email.lower().strip()
    return JSONResponse(_get_settings(email))


@app.put("/api/voice/settings", tags=["Voice Guard"])
async def update_voice_settings(
    body: VoiceSettingsUpdate,
    x_user_email: str = Header(...),
):
    """Toggle voice guard on/off or change sensitivity."""
    email    = x_user_email.lower().strip()
    settings = _get_settings(email)

    if body.voice_guard_enabled is not None:
        settings["voice_guard_enabled"] = body.voice_guard_enabled
    if body.sensitivity is not None:
        settings["sensitivity"] = body.sensitivity
    if body.auto_cancel_seconds is not None:
        settings["auto_cancel_seconds"] = body.auto_cancel_seconds

    return JSONResponse({"message": "Voice guard settings updated.", "settings": settings})


@app.get("/api/voice/keywords", tags=["Keywords"])
async def list_keywords(x_user_email: str = Header(...)):
    """Return the user's current trigger keyword list."""
    email = x_user_email.lower().strip()
    return JSONResponse({"keywords": _get_keywords(email)})


@app.post("/api/voice/keywords", tags=["Keywords"], status_code=201)
async def add_keyword(
    body: KeywordAdd,
    x_user_email: str = Header(...),
):
    """Add a custom trigger keyword (max 10 keywords per user)."""
    email    = x_user_email.lower().strip()
    keywords = _get_keywords(email)

    if len(keywords) >= 10:
        raise HTTPException(status_code=400, detail="Maximum 10 trigger keywords allowed.")

    normalised = body.keyword.strip().title()
    if normalised in [k.strip().title() for k in keywords]:
        raise HTTPException(status_code=409, detail="This keyword already exists.")

    keywords.append(body.keyword.strip())
    return JSONResponse(
        status_code=201,
        content={"message": f"Keyword '{body.keyword.strip()}' added.", "keywords": keywords},
    )


@app.delete("/api/voice/keywords/{keyword}", tags=["Keywords"])
async def remove_keyword(
    keyword: str = Path(..., description="Keyword to remove (URL-encoded)"),
    x_user_email: str = Header(...),
):
    """Remove a trigger keyword. The last keyword cannot be removed."""
    email    = x_user_email.lower().strip()
    keywords = _get_keywords(email)

    if len(keywords) <= 1:
        raise HTTPException(
            status_code=400,
            detail="You must keep at least one trigger keyword.",
        )

    normalised_target = keyword.strip().title()
    before = len(keywords)
    _KEYWORDS[email] = [
        k for k in keywords if k.strip().title() != normalised_target
    ]

    if len(_KEYWORDS[email]) == before:
        raise HTTPException(status_code=404, detail=f"Keyword '{keyword}' not found.")

    return JSONResponse({"message": f"Keyword '{keyword}' removed.", "keywords": _KEYWORDS[email]})


@app.post("/api/voice/trigger", tags=["Voice Guard"])
async def voice_trigger(
    body: VoiceTrigger,
    x_user_email: str = Header(...),
):
    """
    Called by Flutter when the speech recogniser detects a keyword.
    Returns an `action` field:
      • "sos_alert" — Voice Guard active → app should fire SOS
      • "log_only"  — Voice Guard disabled → record only
      • "cancelled" — user cancelled before auto-fire
    """
    email    = x_user_email.lower().strip()
    settings = _get_settings(email)
    logs     = _get_logs(email)

    action = body.action.lower()
    if action not in {"alert", "cancel"}:
        raise HTTPException(status_code=400, detail="action must be 'alert' or 'cancel'.")

    result_action: str
    status_label:  str

    if action == "cancel":
        result_action = "cancelled"
        status_label  = "Cancelled"
    elif settings["voice_guard_enabled"]:
        result_action = "sos_alert"
        status_label  = "Alert Sent"
    else:
        result_action = "log_only"
        status_label  = "Logged Only"

    log_entry = {
        "id":        str(uuid.uuid4()),
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "keyword":   body.keyword,
        "action":    result_action,
        "status":    status_label,
        "lat":       body.lat,
        "lng":       body.lng,
    }
    logs.append(log_entry)

    return JSONResponse({
        "action":    result_action,
        "log_entry": log_entry,
        "message":   (
            "SOS alert triggered by voice keyword."
            if result_action == "sos_alert"
            else f"Event logged: {status_label}."
        ),
    })


@app.get("/api/voice/logs", tags=["Voice Guard"])
async def get_voice_logs(
    limit: int = 20,
    x_user_email: str = Header(...),
):
    """Return voice alert history, newest first."""
    email = x_user_email.lower().strip()
    logs  = _get_logs(email)
    return JSONResponse({
        "logs":  list(reversed(logs[-limit:])),
        "total": len(logs),
    })


@app.delete("/api/voice/logs", tags=["Voice Guard"])
async def clear_voice_logs(x_user_email: str = Header(...)):
    """Clear all voice alert logs for the authenticated user."""
    email        = x_user_email.lower().strip()
    _LOGS[email] = []
    return JSONResponse({"message": "Voice logs cleared."})


# ── Dev runner ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("voice_backend:app", host="0.0.0.0", port=8003, reload=True)
