"""
Women Safety App — Contacts & SOS Backend
==========================================
FastAPI service backing the ContactsScreen and SOS button on HomeScreen.

Endpoints
---------
  GET    /api/contacts           — List all emergency contacts for a user
  POST   /api/contacts           — Add a new emergency contact
  PUT    /api/contacts/{id}      — Update an existing contact
  DELETE /api/contacts/{id}      — Remove an emergency contact
  POST   /api/sos                — Trigger SOS: broadcast alert to all contacts
  GET    /api/sos/history        — List recent SOS events
  GET    /health                 — Liveness probe

Validation rules
----------------
  Name   : 2–60 chars, letters/spaces/hyphens/apostrophes only
  Phone  : 7–15 digits (leading + stripped), digits only after strip
  Relation: 2–30 chars, non-empty string

Run
---
  uvicorn contacts_backend:app --reload --port 8002

Notes
-----
  • Uses an in-memory store keyed by user email (passed as X-User-Email header).
  • In production replace _STORE with a real database (SQLite / Postgres).
  • SOS "broadcast" is simulated here; wire up Twilio / FCM for real SMS/push.
"""

from __future__ import annotations

import re
import uuid
import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException, Header, Path
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="Women Safety — Contacts & SOS API",
    description="Emergency contact management and SOS alerting for the Women Safety app.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── In-memory store ───────────────────────────────────────────────────────────
# { email: [ { id, name, phone, relation, color, created_at } ] }
_STORE: dict[str, list[dict]] = {}

# { email: [ { id, timestamp, lat, lng, contacts_notified } ] }
_SOS_HISTORY: dict[str, list[dict]] = {}

# ── Default seed contacts for demo/testing ────────────────────────────────────
_DEFAULT_CONTACTS = [
    {"name": "Mom",       "phone": "919876543210", "relation": "Mother",      "color": "#E91E63"},
    {"name": "Dad",       "phone": "919876543211", "relation": "Father",      "color": "#1A73E8"},
    {"name": "Sneha",     "phone": "919876543212", "relation": "Best Friend", "color": "#9C27B0"},
    {"name": "Dr. Meera", "phone": "919876543213", "relation": "Doctor",      "color": "#4CAF50"},
]

# ── Validation helpers ─────────────────────────────────────────────────────────
_NAME_RE     = re.compile(r"^[A-Za-z\u00C0-\u024F' \-\.]+$")
_RELATION_RE = re.compile(r"^[A-Za-z\s\-\.]+$")


def _validate_contact_name(name: str) -> str:
    name = name.strip()
    if len(name) < 2:
        raise ValueError("Contact name must be at least 2 characters.")
    if len(name) > 60:
        raise ValueError("Contact name must not exceed 60 characters.")
    if not _NAME_RE.match(name):
        raise ValueError("Name may only contain letters, spaces, hyphens, dots, and apostrophes.")
    return name


def _validate_phone(phone: str) -> str:
    phone = phone.strip().lstrip("+").replace(" ", "").replace("-", "")
    if not phone.isdigit():
        raise ValueError("Phone number must contain digits only (spaces and dashes are stripped).")
    if len(phone) < 7:
        raise ValueError("Phone number must have at least 7 digits.")
    if len(phone) > 15:
        raise ValueError("Phone number must not exceed 15 digits.")
    return phone


def _validate_relation(relation: str) -> str:
    relation = relation.strip()
    if len(relation) < 2:
        raise ValueError("Relation must be at least 2 characters.")
    if len(relation) > 30:
        raise ValueError("Relation must not exceed 30 characters.")
    if not _RELATION_RE.match(relation):
        raise ValueError("Relation may only contain letters, spaces, hyphens, and dots.")
    return relation


def _get_or_seed(email: str) -> list[dict]:
    """Return the contact list for `email`, seeding defaults on first access."""
    if email not in _STORE:
        _STORE[email] = [
            {
                "id":         str(uuid.uuid4()),
                "name":       c["name"],
                "phone":      c["phone"],
                "relation":   c["relation"],
                "color":      c["color"],
                "created_at": datetime.datetime.utcnow().isoformat(),
            }
            for c in _DEFAULT_CONTACTS
        ]
    return _STORE[email]


# ── Pydantic models ───────────────────────────────────────────────────────────

class ContactCreate(BaseModel):
    name:     str
    phone:    str
    relation: str
    color:    Optional[str] = "#9C27B0"   # default purple

    @field_validator("name")
    @classmethod
    def v_name(cls, v: str) -> str:
        return _validate_contact_name(v)

    @field_validator("phone")
    @classmethod
    def v_phone(cls, v: str) -> str:
        return _validate_phone(v)

    @field_validator("relation")
    @classmethod
    def v_relation(cls, v: str) -> str:
        return _validate_relation(v)


class ContactUpdate(BaseModel):
    name:     Optional[str] = None
    phone:    Optional[str] = None
    relation: Optional[str] = None
    color:    Optional[str] = None

    @field_validator("name")
    @classmethod
    def v_name(cls, v: Optional[str]) -> Optional[str]:
        return _validate_contact_name(v) if v is not None else v

    @field_validator("phone")
    @classmethod
    def v_phone(cls, v: Optional[str]) -> Optional[str]:
        return _validate_phone(v) if v is not None else v

    @field_validator("relation")
    @classmethod
    def v_relation(cls, v: Optional[str]) -> Optional[str]:
        return _validate_relation(v) if v is not None else v


class SosRequest(BaseModel):
    lat:     Optional[float] = None
    lng:     Optional[float] = None
    message: Optional[str]   = "SOS! I need help immediately."


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Meta"])
async def health():
    return JSONResponse({
        "status": "ok",
        "users_with_contacts": len(_STORE),
        "total_contacts": sum(len(v) for v in _STORE.values()),
    })


@app.get("/api/contacts", tags=["Contacts"])
async def list_contacts(x_user_email: str = Header(..., description="Authenticated user email")):
    """Return all emergency contacts for the authenticated user."""
    email    = x_user_email.lower().strip()
    contacts = _get_or_seed(email)
    return JSONResponse({"contacts": contacts, "count": len(contacts)})


@app.post("/api/contacts", tags=["Contacts"], status_code=201)
async def add_contact(
    body: ContactCreate,
    x_user_email: str = Header(..., description="Authenticated user email"),
):
    """Add a new emergency contact. Max 10 contacts per user."""
    email    = x_user_email.lower().strip()
    contacts = _get_or_seed(email)

    if len(contacts) >= 10:
        raise HTTPException(
            status_code=400,
            detail="You can have at most 10 emergency contacts.",
        )

    # Duplicate phone check
    if any(c["phone"] == body.phone for c in contacts):
        raise HTTPException(
            status_code=409,
            detail="A contact with this phone number already exists.",
        )

    new_contact = {
        "id":         str(uuid.uuid4()),
        "name":       body.name,
        "phone":      body.phone,
        "relation":   body.relation,
        "color":      body.color or "#9C27B0",
        "created_at": datetime.datetime.utcnow().isoformat(),
    }
    contacts.append(new_contact)

    return JSONResponse(
        status_code=201,
        content={"message": f"Contact '{body.name}' added.", "contact": new_contact},
    )


@app.put("/api/contacts/{contact_id}", tags=["Contacts"])
async def update_contact(
    contact_id: str = Path(..., description="Contact UUID"),
    body: ContactUpdate = ...,
    x_user_email: str = Header(..., description="Authenticated user email"),
):
    """Update name, phone, relation, or color for an existing contact."""
    email    = x_user_email.lower().strip()
    contacts = _get_or_seed(email)

    contact = next((c for c in contacts if c["id"] == contact_id), None)
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found.")

    if body.name     is not None: contact["name"]     = body.name
    if body.phone    is not None: contact["phone"]    = body.phone
    if body.relation is not None: contact["relation"] = body.relation
    if body.color    is not None: contact["color"]    = body.color

    return JSONResponse({"message": "Contact updated.", "contact": contact})


@app.delete("/api/contacts/{contact_id}", tags=["Contacts"])
async def delete_contact(
    contact_id: str = Path(..., description="Contact UUID"),
    x_user_email: str = Header(..., description="Authenticated user email"),
):
    """Remove an emergency contact."""
    email    = x_user_email.lower().strip()
    contacts = _get_or_seed(email)

    before = len(contacts)
    _STORE[email] = [c for c in contacts if c["id"] != contact_id]

    if len(_STORE[email]) == before:
        raise HTTPException(status_code=404, detail="Contact not found.")

    return JSONResponse({"message": "Contact removed."})


@app.post("/api/sos", tags=["SOS"])
async def trigger_sos(
    body: SosRequest,
    x_user_email: str = Header(..., description="Authenticated user email"),
):
    """
    Trigger an SOS alert.
    Notifies all saved emergency contacts (simulated here — wire up Twilio/FCM for real dispatch).
    Records the event in SOS history.
    """
    email    = x_user_email.lower().strip()
    contacts = _get_or_seed(email)

    if not contacts:
        raise HTTPException(
            status_code=400,
            detail="No emergency contacts found. Please add at least one contact before sending SOS.",
        )

    event_id  = str(uuid.uuid4())
    timestamp = datetime.datetime.utcnow().isoformat()

    # In production: iterate contacts and fire SMS / push notification
    notified = [{"name": c["name"], "phone": c["phone"]} for c in contacts]

    event = {
        "id":                event_id,
        "timestamp":         timestamp,
        "lat":               body.lat,
        "lng":               body.lng,
        "message":           body.message,
        "contacts_notified": notified,
    }

    _SOS_HISTORY.setdefault(email, []).append(event)

    location_str = (
        f"{body.lat:.5f}, {body.lng:.5f}" if body.lat and body.lng else "unknown"
    )

    return JSONResponse({
        "message":           f"SOS alert dispatched to {len(notified)} contact(s).",
        "event_id":          event_id,
        "timestamp":         timestamp,
        "location":          location_str,
        "contacts_notified": notified,
    })


@app.get("/api/sos/history", tags=["SOS"])
async def sos_history(x_user_email: str = Header(..., description="Authenticated user email")):
    """Return recent SOS events (newest first, max 20)."""
    email  = x_user_email.lower().strip()
    events = _SOS_HISTORY.get(email, [])
    return JSONResponse({"events": list(reversed(events[-20:]))})


# ── Dev runner ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("contacts_backend:app", host="0.0.0.0", port=8002, reload=True)
