# 🛡️ Women Safety App — Flutter UI

A polished, production-ready Flutter UI for a **Women Safety Environment** app featuring animated login and registration screens.

---

## 📁 Project Structure

```
login-ui/
├── lib/
│   ├── main.dart                   # App entry point & routing
│   ├── theme/
│   │   └── app_theme.dart          # Colors, gradients, button/input styles
│   └── screens/
│       ├── login_screen.dart       # Login screen
│       └── register_screen.dart    # Registration screen
└── pubspec.yaml
```

---

## 📱 Screens

### 🔐 Login Screen
| Feature | Details |
|---|---|
| Title | "Sign In to your Account" |
| Subtitle | Descriptive helper text |
| Email field | Validated email with prefix icon |
| Password field | Show/hide toggle |
| Forgot Password? | Opens bottom sheet modal with reset flow |
| Log In button | Loading spinner on submit |
| OR divider | Styled with lines |
| Google login | Brand-colored icon button |
| Facebook login | Brand-colored icon button |
| Instagram login | Brand-colored icon button |
| Sign Up link | Navigates to Registration |

### 📝 Registration Screen
| Field | Details |
|---|---|
| Full Name | Text, min 2 chars |
| Age | Numeric only, 10–120 |
| Gender | Dropdown (Female/Male/Non-binary/Prefer not to say) |
| Address | Multi-line textarea, min 10 chars |
| Contact Number | Phone number, digits only |
| Terms checkbox | Animated checkmark |
| Create Account button | Loading state + success dialog |

---

## 🎨 Theme

| Color Role | Hex | Usage |
|---|---|---|
| Primary Blue | `#1A73E8` | Buttons, links, icons |
| Deep Blue | `#0D47A1` | Gradient start |
| Accent Green | `#00C853` | Success, highlights |
| Accent Purple | `#7B1FA2` | Accents, register button |
| Deep Purple | `#6A1B9A` | Gradient end |

Background uses a 4-stop diagonal gradient from deep indigo → blue → purple → deep purple.

---

## ✨ Enhancements Added

- **Entrance animations**: fade + slide-up on both screens
- **Forgot Password bottom sheet**: with email input and confirmation state
- **Password visibility toggle**: show/hide password
- **Form validation**: all fields validated with helpful messages
- **Animated checkbox**: for Terms & Conditions
- **Success dialog**: after registration with user's name
- **Loading spinners**: on both buttons during async operations
- **Social login snackbars**: feedback on social button taps
- **Safety tip banner**: on registration screen
- **Progress bar**: visual registration progress indicator
- **Smooth page transition**: fade transition between screens
- **Google Fonts (Poppins)**: consistent typography throughout
- **Bounce scroll physics**: smooth scrolling on both screens
- **Shield logo badge**: branded app icon on login screen

---

## 🚀 Getting Started

```bash
cd login-ui
flutter pub get
flutter run
```

### Dependencies
```yaml
font_awesome_flutter: ^10.7.0   # Social icons (Google, Facebook, Instagram)
google_fonts: ^6.2.1            # Poppins font
animated_text_kit: ^4.2.2       # Optional animated text
```
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

