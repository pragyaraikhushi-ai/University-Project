"""
Women Safety App — Map Backend
FastAPI server that wraps the Google Maps Platform APIs to provide:
  • /api/geocode          — address → lat/lng
  • /api/routes           — origin → destination with safety-ranked routes
  • /api/nearby-help      — police stations, hospitals, safety centres near a point
  • /api/static-map-url   — Static Maps URL for Flutter Image.network()
  • /health               — liveness check

Run:
    uvicorn main:app --reload --port 8000

Env vars (set in .env or export directly):
    GOOGLE_MAPS_API_KEY   — your Google Maps Platform server-side API key
    ALLOWED_ORIGINS       — comma-separated CORS origins (default: all localhost)
"""

import os
import math
import httpx

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import Optional
from dotenv import load_dotenv

# ── Bootstrap ─────────────────────────────────────────────────────────────────
load_dotenv()

GOOGLE_MAPS_API_KEY: str = os.getenv("GOOGLE_MAPS_API_KEY", "")

app = FastAPI(
    title="Women Safety — Map API",
    description="Google Maps-powered backend for the Women Safety Flutter app.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # lock this down in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Google Maps base URLs ──────────────────────────────────────────────────────
GMAPS_GEOCODE_URL       = "https://maps.googleapis.com/maps/api/geocode/json"
GMAPS_DIRECTIONS_URL    = "https://maps.googleapis.com/maps/api/directions/json"
GMAPS_PLACES_URL        = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
GMAPS_STATIC_URL        = "https://maps.googleapis.com/maps/api/staticmap"

# ── Helpers ───────────────────────────────────────────────────────────────────

def _require_key() -> str:
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="GOOGLE_MAPS_API_KEY is not configured. Set it in map-backend/.env",
        )
    return GOOGLE_MAPS_API_KEY


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
         * math.sin(dlng / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))


def _safety_score(route: dict, index: int) -> float:
    """
    Heuristic safety score 0-100.
    Higher = safer. Based on step count, average speed, and route preference order.
    """
    leg = route["legs"][0]
    steps       = len(leg["steps"])
    distance_m  = leg["distance"]["value"]
    duration_s  = leg["duration"]["value"]

    avg_speed = (distance_m / 1000) / (duration_s / 3600) if duration_s > 0 else 10
    step_penalty = min(steps * 1.5, 40)
    speed_bonus  = min(avg_speed * 0.8, 30)
    index_bonus  = max(10 - index * 4, 0)

    score = 100 - step_penalty + speed_bonus - index_bonus
    return round(max(0.0, min(100.0, score)), 1)


# ── Endpoints ──────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Meta"])
async def health():
    """Liveness probe — confirms the server is running and shows API key status."""
    return JSONResponse({
        "status": "ok",
        "api_key_configured": bool(GOOGLE_MAPS_API_KEY),
    })


@app.get("/api/geocode", tags=["Maps"])
async def geocode(address: str = Query(..., description="Human-readable address to geocode")):
    """Convert an address to lat/lng using Google Geocoding API."""
    key = _require_key()
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(GMAPS_GEOCODE_URL, params={"address": address, "key": key})
    data = resp.json()

    if data.get("status") != "OK" or not data.get("results"):
        raise HTTPException(status_code=404, detail=f"Geocode failed: {data.get('status')}")

    result = data["results"][0]
    loc    = result["geometry"]["location"]
    return JSONResponse({
        "address":           address,
        "lat":               loc["lat"],
        "lng":               loc["lng"],
        "formatted_address": result["formatted_address"],
        "place_id":          result["place_id"],
    })


@app.get("/api/routes", tags=["Maps"])
async def get_routes(
    origin_lat:   float = Query(..., description="Origin latitude"),
    origin_lng:   float = Query(..., description="Origin longitude"),
    dest_lat:     float = Query(..., description="Destination latitude"),
    dest_lng:     float = Query(..., description="Destination longitude"),
    mode:         str   = Query("walking", description="Travel mode: walking | driving | transit | bicycling"),
    alternatives: bool  = Query(True, description="Request multiple alternative routes"),
):
    """
    Fetch routes from Google Directions API and rank them by a heuristic safety score.
    Returns up to 3 routes labelled Safest / Fastest / Scenic.
    """
    key = _require_key()
    params = {
        "origin":       f"{origin_lat},{origin_lng}",
        "destination":  f"{dest_lat},{dest_lng}",
        "mode":         mode,
        "alternatives": "true" if alternatives else "false",
        "key":          key,
    }

    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(GMAPS_DIRECTIONS_URL, params=params)
    data = resp.json()

    if data.get("status") not in ("OK", "ZERO_RESULTS"):
        raise HTTPException(status_code=502, detail=f"Directions API error: {data.get('status')}")

    raw_routes = data.get("routes", [])
    if not raw_routes:
        raise HTTPException(status_code=404, detail="No routes found between these points.")

    # Sort by safety score (highest first)
    scored = sorted(
        [(r, _safety_score(r, i)) for i, r in enumerate(raw_routes)],
        key=lambda x: x[1],
        reverse=True,
    )

    labels = ["Safest", "Fastest", "Scenic"]
    colors = ["#4CAF50", "#FFB300", "#00BCD4"]
    result_routes = []

    for idx, (route, score) in enumerate(scored[:3]):
        leg   = route["legs"][0]
        label = labels[idx]
        color = colors[idx]

        safety_label = (
            "High Safety"     if score >= 70 else
            "Moderate Safety" if score >= 40 else
            "Low Safety"
        )

        steps = [
            {
                "instruction": s.get("html_instructions", ""),
                "distance":    s["distance"]["text"],
                "duration":    s["duration"]["text"],
                "start_lat":   s["start_location"]["lat"],
                "start_lng":   s["start_location"]["lng"],
                "end_lat":     s["end_location"]["lat"],
                "end_lng":     s["end_location"]["lng"],
            }
            for s in leg["steps"]
        ]

        result_routes.append({
            "label":        label,
            "distance":     leg["distance"]["text"],
            "duration":     leg["duration"]["text"],
            "safety_score": score,
            "safety_label": safety_label,
            "summary":      route.get("summary", ""),
            "polyline":     route["overview_polyline"]["points"],
            "steps":        steps,
            "color_hex":    color,
        })

    return JSONResponse({
        "origin_lat":      origin_lat,
        "origin_lng":      origin_lng,
        "destination_lat": dest_lat,
        "destination_lng": dest_lng,
        "routes":          result_routes,
    })


@app.get("/api/nearby-help", tags=["Maps"])
async def nearby_help(
    lat:    float = Query(..., description="User latitude"),
    lng:    float = Query(..., description="User longitude"),
    radius: int   = Query(2000, description="Search radius in metres (max 5000)"),
):
    """
    Find police stations, hospitals, and women's safety centres using Google Places.
    """
    key    = _require_key()
    radius = min(radius, 5000)

    categories = [
        ("police",   "police",                  "police"),
        ("hospital", "hospital",                "hospital"),
        ("safety",   "local_government_office", "safety"),
    ]

    places = []

    async with httpx.AsyncClient(timeout=15) as client:
        for cat_label, place_type, icon_key in categories:
            params = {
                "location": f"{lat},{lng}",
                "radius":   radius,
                "type":     place_type,
                "key":      key,
            }
            resp = await client.get(GMAPS_PLACES_URL, params=params)
            data = resp.json()

            for result in data.get("results", [])[:3]:
                loc  = result["geometry"]["location"]
                dist = _haversine_km(lat, lng, loc["lat"], loc["lng"])

                # For the 'safety' category only include women-related venues
                if cat_label == "safety":
                    name_lower = result.get("name", "").lower()
                    if not any(kw in name_lower for kw in (
                        "women", "woman", "safety", "helpline", "ngo", "centre", "center"
                    )):
                        continue

                places.append({
                    "name":        result.get("name", "Unknown"),
                    "category":    cat_label,
                    "distance_km": round(dist, 2),
                    "lat":         loc["lat"],
                    "lng":         loc["lng"],
                    "place_id":    result.get("place_id", ""),
                    "icon":        icon_key,
                    "open_now":    result.get("opening_hours", {}).get("open_now"),
                })

    places.sort(key=lambda p: p["distance_km"])

    return JSONResponse({"origin_lat": lat, "origin_lng": lng, "places": places})


@app.get("/api/static-map-url", tags=["Maps"])
async def static_map_url(
    lat:      float           = Query(..., description="Centre latitude"),
    lng:      float           = Query(..., description="Centre longitude"),
    dest_lat: Optional[float] = Query(None, description="Destination latitude"),
    dest_lng: Optional[float] = Query(None, description="Destination longitude"),
    polyline: Optional[str]   = Query(None, description="Encoded polyline to draw"),
    zoom:     int             = Query(15,   description="Zoom level 0-21"),
    width:    int             = Query(640,  description="Image width px (max 640)"),
    height:   int             = Query(400,  description="Image height px (max 640)"),
):
    """
    Build a Google Static Maps URL.  Flutter can load it with Image.network().
    No image bytes are fetched server-side — only the URL is returned.
    """
    key    = _require_key()
    width  = min(width, 640)
    height = min(height, 640)

    params = [
        f"center={lat},{lng}",
        f"zoom={zoom}",
        f"size={width}x{height}",
        "maptype=roadmap",
        f"markers=color:green%7Clabel:U%7C{lat},{lng}",
    ]

    if dest_lat is not None and dest_lng is not None:
        params.append(f"markers=color:red%7Clabel:D%7C{dest_lat},{dest_lng}")

    if polyline:
        params.append(f"path=enc:{polyline}")

    params.append(f"key={key}")

    url = GMAPS_STATIC_URL + "?" + "&".join(params)
    return JSONResponse({"url": url, "width": width, "height": height})


# ── Dev runner ─────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
