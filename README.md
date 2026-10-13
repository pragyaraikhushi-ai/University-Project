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
