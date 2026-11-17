"""
Women Safety App — Location Tracking Backend
=============================================
FastAPI service backing the MapScreen's live-location sharing feature.

Endpoints
---------
  POST /api/track                  — Receive a GPS ping from the Flutter app
  GET  /api/location/current       — Return the user's last known location
  GET  /api/location/history       — Return location ping history (newest first)
  POST /api/sos-location           — Record an SOS event with current location
  GET  /api/location/shared-with   — List contacts currently receiving the live feed
  POST /api/location/share         — Start/stop sharing with a specific contact
  GET  /health                     — Liveness probe

GPS ping schema
---------------
  lat      : float  — Latitude  (-90 to 90)
  lng      : float  — Longitude (-180 to 180)
  accuracy : float  — Horizontal accuracy in metres (optional)
  sharing  : bool   — Whether the user has location sharing toggled on

Safety rules
------------
  • Latitude must be in [-90, 90].
  • Longitude must be in [-180, 180].
  • Accuracy, if provided, must be non-negative.

Run
---
  uvicorn location_backend:app --reload --port 8005
"""

from __future__ import annotations

import datetime
import math
import uuid
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="Women Safety — Location API",
    description="Live GPS tracking and SOS location recording for the Women Safety app.",
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
# { email: { lat, lng, accuracy, sharing, updated_at } }
_CURRENT: dict[str, dict] = {}

# { email: [ { lat, lng, accuracy, sharing, timestamp }, ... ] }
_HISTORY: dict[str, list[dict]] = {}

# { email: [ { contact_name, contact_phone, sharing } ] }
_SHARED_WITH: dict[str, list[dict]] = {}

# { email: [ { id, timestamp, lat, lng, message } ] }
_SOS_LOCATIONS: dict[str, list[dict]] = {}

# ── Validation ────────────────────────────────────────────────────────────────

def _validate_lat(lat: float) -> float:
    if not -90.0 <= lat <= 90.0:
        raise ValueError("Latitude must be between -90 and 90.")
    return round(lat, 7)


def _validate_lng(lng: float) -> float:
    if not -180.0 <= lng <= 180.0:
        raise ValueError("Longitude must be between -180 and 180.")
    return round(lng, 7)


def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Return distance in metres between two GPS points."""
    R   = 6_371_000.0
    phi = math.radians
    d1  = phi(lat2 - lat1)
    d2  = phi(lng2 - lng1)
    a   = (math.sin(d1 / 2) ** 2
           + math.cos(phi(lat1)) * math.cos(phi(lat2)) * math.sin(d2 / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))


# ── Pydantic models ───────────────────────────────────────────────────────────

class LocationPing(BaseModel):
    lat:      float
    lng:      float
    accuracy: Optional[float] = None   # metres
    sharing:  bool            = True

    @field_validator("lat")
    @classmethod
    def v_lat(cls, v: float) -> float:
        return _validate_lat(v)

    @field_validator("lng")
    @classmethod
    def v_lng(cls, v: float) -> float:
        return _validate_lng(v)

    @field_validator("accuracy")
    @classmethod
    def v_accuracy(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and v < 0:
            raise ValueError("accuracy must be non-negative.")
        return v


class SosLocationReport(BaseModel):
    lat:     float
    lng:     float
    message: Optional[str] = "SOS! I need immediate help."

    @field_validator("lat")
    @classmethod
    def v_lat(cls, v: float) -> float:
        return _validate_lat(v)

    @field_validator("lng")
    @classmethod
    def v_lng(cls, v: float) -> float:
        return _validate_lng(v)


class ShareToggle(BaseModel):
    contact_name:  str
    contact_phone: str
    sharing:       bool


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Meta"])
async def health():
    return JSONResponse({
        "status":           "ok",
        "tracked_users":    len(_CURRENT),
        "sos_events_total": sum(len(v) for v in _SOS_LOCATIONS.values()),
    })


@app.post("/api/track", tags=["Location"])
async def track(
    body: LocationPing,
    x_user_email: str = Header(...),
):
    """
    Receive a GPS ping from the Flutter app.
    Returns distance moved since last ping (metres) so the app can decide
    whether to show a movement notification.
    """
    email     = x_user_email.lower().strip()
    now       = datetime.datetime.utcnow().isoformat()
    prev      = _CURRENT.get(email)

    distance_m: Optional[float] = None
    if prev:
        distance_m = round(
            _haversine_m(prev["lat"], prev["lng"], body.lat, body.lng), 1
        )

    record = {
        "lat":        body.lat,
        "lng":        body.lng,
        "accuracy":   body.accuracy,
        "sharing":    body.sharing,
        "updated_at": now,
    }
    _CURRENT[email] = record

    # Keep rolling history of last 500 pings
    history = _HISTORY.setdefault(email, [])
    history.append({**record, "timestamp": now})
    if len(history) > 500:
        _HISTORY[email] = history[-500:]

    return JSONResponse({
        "status":      "ok",
        "lat":         body.lat,
        "lng":         body.lng,
        "sharing":     body.sharing,
        "distance_m":  distance_m,
        "updated_at":  now,
    })


@app.get("/api/location/current", tags=["Location"])
async def current_location(x_user_email: str = Header(...)):
    """Return the user's last known GPS position."""
    email  = x_user_email.lower().strip()
    record = _CURRENT.get(email)
    if not record:
        raise HTTPException(
            status_code=404,
            detail="No location data found. The app has not sent a GPS ping yet.",
        )
    return JSONResponse(record)


@app.get("/api/location/history", tags=["Location"])
async def location_history(
    limit: int = 50,
    x_user_email: str = Header(...),
):
    """Return up to `limit` recent GPS pings, newest first."""
    email   = x_user_email.lower().strip()
    history = _HISTORY.get(email, [])
    page    = list(reversed(history[-limit:]))
    return JSONResponse({
        "pings": page,
        "total": len(history),
    })


@app.post("/api/sos-location", tags=["SOS"])
async def sos_location(
    body: SosLocationReport,
    x_user_email: str = Header(...),
):
    """
    Record the user's location at the moment an SOS is triggered.
    Called alongside contacts_backend POST /api/sos for a complete SOS record.
    """
    email     = x_user_email.lower().strip()
    now       = datetime.datetime.utcnow().isoformat()
    event_id  = str(uuid.uuid4())

    event = {
        "id":        event_id,
        "timestamp": now,
        "lat":       body.lat,
        "lng":       body.lng,
        "message":   body.message,
        "maps_url":  (
            f"https://www.google.com/maps?q={body.lat},{body.lng}"
        ),
    }
    _SOS_LOCATIONS.setdefault(email, []).append(event)

    # Also update current position
    _CURRENT[email] = {
        "lat":        body.lat,
        "lng":        body.lng,
        "accuracy":   None,
        "sharing":    True,
        "updated_at": now,
    }

    return JSONResponse({
        "message":  "SOS location recorded.",
        "event_id": event_id,
        "maps_url": event["maps_url"],
        "lat":      body.lat,
        "lng":      body.lng,
    })


@app.get("/api/location/shared-with", tags=["Sharing"])
async def shared_with(x_user_email: str = Header(...)):
    """Return the list of contacts receiving the user's live location."""
    email   = x_user_email.lower().strip()
    sharing = _SHARED_WITH.get(email, [])
    active  = [s for s in sharing if s["sharing"]]
    return JSONResponse({
        "shared_with": sharing,
        "active_count": len(active),
    })


@app.post("/api/location/share", tags=["Sharing"])
async def toggle_share(
    body: ShareToggle,
    x_user_email: str = Header(...),
):
    """Start or stop sharing live location with a specific contact."""
    email   = x_user_email.lower().strip()
    sharing = _SHARED_WITH.setdefault(email, [])

    # Find or create entry
    for entry in sharing:
        if entry["contact_phone"] == body.contact_phone:
            entry["sharing"] = body.sharing
            break
    else:
        sharing.append({
            "contact_name":  body.contact_name,
            "contact_phone": body.contact_phone,
            "sharing":       body.sharing,
        })

    verb = "started" if body.sharing else "stopped"
    return JSONResponse({
        "message":     f"Location sharing {verb} with {body.contact_name}.",
        "shared_with": sharing,
    })


# ── Dev runner ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("location_backend:app", host="0.0.0.0", port=8005, reload=True)
