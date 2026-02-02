# BizLedger (v2.3.0)
> **The Ultimate Business & Event Management Solution**

BizLedger is a high-performance, security-focused Flutter application designed for professionals. It combines robust financial tracking with a stunning Material You interface, seamless biometric security, and dynamic business logic adaptability.

---

## 🏗️ Architecture & Performance

BizLedger is built on a **Service-Oriented Architecture (SOA)**, ensuring separation of concerns, scalability, and testability.

### 🚀 Performance Highlights
- **Optimized Rendering**: Maintains **60 FPS** even with complex gradients and shimmer animations using `RepaintBoundary` and optimized `AnimatedBuilder` layers.
- **Tree Shaking**: Release builds utilize aggressive tree-shaking, reducing font assets by **~99%** (from 2MB to <15KB).
- **Smart Caching**: `SharedPreferences` and In-Memory caching strategies minimize disk I/O for frequent setting reads.
- **Lazy Loading**: Dynamic imports and lazy service initialization ensure rapid cold-start times (<1.2s).

### 🔒 Security Architecture
- **Native Integration**: Implements `FlutterFragmentActivity` to leverage Android's hardware-backed Biometric Prompt.
- **Session Security**: Uses **RAM-based Session Tracking** for authentication. Auth state is never written to disk, ensuring that every app kill/restart triggers a mandatory security check.
- **Lifecycle Awareness**: `AuthGate` intercepts app resume events to enforce lock screens instantly when returning from the background.

---

## 📂 Project Structure

A clean, modular codebase organized by feature and layer.

```bash
lib/
├── main.dart                  # Application Entry & Global Providers
├── models/                    # Data Models (Immutable)
│   ├── booking.dart           # Core Booking Entity
│   ├── business_type.dart     # Business Configuration Logic
│   └── payment.dart           # Financial Transaction Models
├── services/                  # Business Logic & Infrastructure
│   ├── biometric_service.dart # Hardware Security & Session Auth
│   ├── database_service.dart  # Persistence Layer (JSON/SQLite)
│   ├── theme_service.dart     # Dynamic Material You Engine
│   └── pdf_service.dart       # Reporting Engine
├── theme/                     # Design System
│   └── app_theme.dart         # Light/Dark/Dynamic Theme Definitions
├── ui/                        # Presentation Layer
│   ├── home_screen.dart       # Dashboard & KPI Visualization
│   ├── settings_screen.dart   # Configuration & Preferences
│   ├── lock_screen.dart       # Biometric Security UI
│   ├── hiring_screen.dart     # Dynamic Form Handling
│   └── widgets/               # Reusable Components
│       ├── performance_overlay.dart
│       └── shimmer_text.dart  # Premium Visual Effects
└── utils/                     # Helpers & Extensions
    ├── pdf_generator.dart     # Invoice Generation Logic
    └── haptics.dart           # Custom Haptic Feedback Engine
```

---

## ✨ Key Features

### 1. Dynamic Business Types
The application morphs its entire UI/UX based on the selected industry:
- **Catering**: Tracks food costs, menu items, and client counts.
- **Event Planning**: Manages venues, schedules, and guest lists.
- **Photography**: Tracks shoots, deliverables, and album statuses.
- **General Business**: A streamlined ledger for universal use.

### 2. Material You & Theming
- **Wallpaper Extraction**: Automatically extracts dominant colors from the user's wallpaper (Android 12+).
- **True Dark Mode**: Engineered with high-contrast variants for perfect visibility in low light.
- **Platinum Animations**: Custom-built visuals including "Gold Shimmer", "Pulse", and "Elastic Scale" user interactions.

### 3. Global Localization
Fully localized for global deployment with RTL support:
- 🇺🇸 English
- 🇮🇳 Hindi, Malayalam, Tamil
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇸🇦 Arabic (RTL)
- 🇩🇪 German
- 🇮🇩 Indonesian
- 🇵🇹 Portuguese

---

## 🛠️ Tech Stack

| Component | Technology | Description |
|-----------|------------|-------------|
| **Core** | Flutter 3.x | Cross-platform UI Toolkit |
| **Language** | Dart 3.x | Strongly typed, null-safe language |
| **Security** | Local Auth | Hardware-backed Biometrics |
| **State** | Provider/SOA | Simple, scalable state management |
| **Storage** | SharedPrefs | Lightweight key-value persistence |
| **Design** | Material 3 | Latest Google Design Guidelines |

---

## 📦 Installation

To build and run this project locally:

1. **Clone the Repository**
   ```bash
   git clone https://github.com/kiran-embedded/-vownote-app.git
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run Application**
   ```bash
   flutter run --release
   ```

---

*© 2026 Developed by Kiran. All Rights Reserved.*
