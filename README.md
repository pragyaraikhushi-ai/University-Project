# Women Safety App — Map Backend

FastAPI-powered Google Maps backend for the Women Safety Flutter app.
Provides current-location-aware routing, safety-scored routes, and
nearby emergency services (police, hospitals, women's safety centres).

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness check — confirms server is up and API key is set |
| GET | `/api/geocode` | Convert an address string to lat/lng |
| GET | `/api/routes` | Fetch safety-ranked routes between two coordinates |
| GET | `/api/nearby-help` | Find police stations, hospitals, safety centres near a point |
| GET | `/api/static-map-url` | Get a Google Static Maps image URL for Flutter `Image.network()` |

Interactive documentation: **http://localhost:8000/docs** (Swagger UI)

---

## Setup

### 1 — Python requirement

Use **Python 3.12** (pydantic-core has pre-built wheels for 3.12).

```
py -3.12 --version   # should print Python 3.12.x
```

### 2 — Install dependencies

```bash
cd map-backend
py -3.12 -m pip install -r requirements.txt
```

### 3 — Get a Google Maps API key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable these APIs:
   - **Geocoding API**
   - **Directions API**
   - **Places API**
   - **Maps Static API**
4. Create an API key: **APIs & Services → Credentials → Create Credentials → API Key**
5. (Recommended) Restrict the key to your server's IP

### 4 — Configure the key

```bash
# Copy the example file
copy .env.example .env

# Open .env and replace YOUR_GOOGLE_MAPS_API_KEY_HERE with your real key
```

`.env` contents:
```
GOOGLE_MAPS_API_KEY=AIzaSy...your_key_here
```

### 5 — Run the server

```bash
# Using Python 3.12 directly:
py -3.12 -m uvicorn main:app --reload --port 8000

# Or using the uvicorn binary (if Python312\Scripts is on PATH):
uvicorn main:app --reload --port 8000
```

Server starts at **http://localhost:8000**

---

## Flutter Integration

The Flutter `map_screen.dart` connects to this backend.
The backend URL defaults to `http://10.0.2.2:8000` (Android emulator)
or `http://localhost:8000` (web / iOS simulator).

### Example — Get safe routes

```
GET http://localhost:8000/api/routes
    ?origin_lat=28.6139&origin_lng=77.2090
    &dest_lat=28.6448&dest_lng=77.2167
    &mode=walking
```

Response:
```json
{
  "routes": [
    {
      "label": "Safest",
      "distance": "3.2 km",
      "duration": "42 mins",
      "safety_score": 82.5,
      "safety_label": "High Safety",
      "color_hex": "#4CAF50",
      "polyline": "encoded...",
      "steps": [...]
    }
  ]
}
```

### Example — Nearby help

```
GET http://localhost:8000/api/nearby-help?lat=28.6139&lng=77.2090&radius=2000
```

### Example — Static map image

```
GET http://localhost:8000/api/static-map-url?lat=28.6139&lng=77.2090&zoom=15
```

Returns a URL you pass directly to Flutter's `Image.network(url)`.

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| fastapi | 0.115.5 | Web framework |
| uvicorn[standard] | 0.32.1 | ASGI server |
| httpx | 0.27.2 | Async HTTP client for Google Maps API calls |
| python-dotenv | 1.0.1 | Load `GOOGLE_MAPS_API_KEY` from `.env` |
| pydantic | 2.9.2 | Request/response validation |
