"""
Women Safety App — Unified Application Server
==============================================
Single entry-point that mounts all backend micro-services as sub-applications
under one FastAPI root so the Flutter app only needs ONE base URL.

Port layout
-----------
  This server  : 8000  (default, change with --port)
  Standalone alternatives (each can also run independently):
    auth_backend.py      → port 8001
    contacts_backend.py  → port 8002
    voice_backend.py     → port 8003
    settings_backend.py  → port 8004
    location_backend.py  → port 8005

Mount prefixes
--------------
  /auth       → auth_backend       (register, login, social-login, etc.)
  /contacts   → contacts_backend   (emergency contacts + SOS dispatch)
  /voice      → voice_backend      (voice guard keywords + logs)
  /settings   → settings_backend   (app settings + profile)
  /location   → location_backend   (GPS tracking + SOS location)
  /map        → main (map backend) (geocode, routes, nearby-help)

All mounted apps include their own /health and /docs endpoints, e.g.:
  http://localhost:8000/auth/docs
  http://localhost:8000/contacts/docs
  ...

Root endpoints
--------------
  GET /           — API overview + all mount prefixes
  GET /health     — Aggregate liveness probe (checks all sub-apps)
  GET /docs       — This root app's own OpenAPI docs

Run
---
  uvicorn app_server:app --reload --port 8000

  Or using the helper script:
    python app_server.py

Environment (.env)
------------------
  Copy env.example → .env and fill in your keys.
  All sub-apps share the same .env loaded here.
"""

from __future__ import annotations

import datetime
import importlib
import sys

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

# ── Load environment variables once for the whole process ─────────────────────
load_dotenv()

# ── Root application ──────────────────────────────────────────────────────────
app = FastAPI(
    title="Women Safety App — Unified API",
    description=(
        "Central gateway that aggregates all Women Safety micro-services. "
        "Flutter points every HTTP call at this single base URL."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Mount sub-applications ────────────────────────────────────────────────────
# We import each backend module and mount its FastAPI `app` object.
# If a module fails to import (e.g. missing optional dep) we skip it gracefully.

_MOUNTS: list[tuple[str, str, str]] = [
    # (url_prefix, module_name, description)
    ("/auth",     "auth_backend",     "Authentication — register, login, social OAuth"),
    ("/contacts", "contacts_backend", "Emergency contacts CRUD + SOS dispatch"),
    ("/voice",    "voice_backend",    "Voice guard — keywords, trigger, logs"),
    ("/settings", "settings_backend", "App settings + user profile"),
    ("/location", "location_backend", "Live GPS tracking + SOS location"),
    ("/map",      "main",             "Map — geocode, routes, nearby help (Google Maps)"),
]

_mounted: list[dict] = []

for prefix, module_name, description in _MOUNTS:
    try:
        mod        = importlib.import_module(module_name)
        sub_app    = getattr(mod, "app")
        app.mount(prefix, sub_app)
        _mounted.append({
            "prefix":      prefix,
            "module":      module_name,
            "description": description,
            "status":      "mounted",
            "docs":        f"{prefix}/docs",
        })
        print(f"  ✓  Mounted /{module_name:20s} → {prefix}", file=sys.stderr)
    except Exception as exc:
        _mounted.append({
            "prefix":      prefix,
            "module":      module_name,
            "description": description,
            "status":      f"error: {exc}",
            "docs":        None,
        })
        print(f"  ✗  Failed to mount {module_name}: {exc}", file=sys.stderr)


# ── Root endpoints ─────────────────────────────────────────────────────────────

@app.get("/", tags=["Meta"])
async def root():
    """API overview — lists every mounted sub-application and its docs URL."""
    return JSONResponse({
        "app":       "Women Safety — Unified API",
        "version":   "1.0.0",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "services":  _mounted,
        "quick_links": {
            "root_docs":          "/docs",
            "auth_docs":          "/auth/docs",
            "contacts_docs":      "/contacts/docs",
            "voice_docs":         "/voice/docs",
            "settings_docs":      "/settings/docs",
            "location_docs":      "/location/docs",
            "map_docs":           "/map/docs",
        },
    })


@app.get("/health", tags=["Meta"])
async def aggregate_health():
    """Aggregate liveness probe — reports status of every mounted service."""
    services = []
    all_ok   = True

    for entry in _mounted:
        ok = "error" not in entry["status"]
        if not ok:
            all_ok = False
        services.append({
            "prefix":      entry["prefix"],
            "module":      entry["module"],
            "description": entry["description"],
            "healthy":     ok,
            "detail":      entry["status"],
        })

    return JSONResponse(
        status_code=200,
        content={
            "status":    "ok" if all_ok else "degraded",
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "services":  services,
        },
    )


@app.get("/api/ping", tags=["Meta"])
async def ping():
    """Quick connectivity check for Flutter app startup."""
    return JSONResponse({"ping": "pong", "ts": datetime.datetime.utcnow().isoformat()})


# ── Dev runner ────────────────────────────────────────────────────────────────
# NOTE: Do NOT run this file directly with `uvicorn app_server:app` —
# AppLocker on some Windows machines blocks uvicorn.exe.
# Use instead:  python -m uvicorn app_server:app --reload --port 8000
if __name__ == "__main__":
    import uvicorn

    print("\n+--------------------------------------------------+")
    print("|   Women Safety App -- Unified Backend Server    |")
    print("+--------------------------------------------------+")
    print("|  Root URL :  http://localhost:8000               |")
    print("|  Root docs:  http://localhost:8000/docs          |")
    print("|  Auth docs:  http://localhost:8000/auth/docs     |")
    print("|  SOS  docs:  http://localhost:8000/contacts/docs |")
    print("|  Voice docs: http://localhost:8000/voice/docs    |")
    print("|  Map   docs: http://localhost:8000/map/docs      |")
    print("+--------------------------------------------------+\n")

    uvicorn.run("app_server:app", host="0.0.0.0", port=8000, reload=True)
