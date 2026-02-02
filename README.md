# BizLedger (formerly VowNote) v2.3.0

**The Ultimate Business & Event Management Tool for Professionals.**

BizLedger is a Flutter-based mobile application designed for event planners, caterers, and general businesses to manage bookings, track payments, and generate professional PDF reports. It features a stunning Material You design, robust biometric security, and global localization support.

## 🚀 Key Features

### 1. Dynamic Business Types
- **Generic Support**: Tailored modes for "General Business", "Catering", "Event Planning", and "Photography".
- **Contextual UI**: terminology (e.g., "Bride/Groom" vs "Client") and icons adapt instantly based on the selected business type.
- **Smart Forms**: Booking forms automatically hide/show relevant fields (e.g., showing specific event details only for Wedding contexts).

### 2. 🎨 Material You Design & Theming
- **Dynamic Colors**: Extracts colors from your device's wallpaper (Android 12+) to theme the entire app.
- **Dark Mode**: Fully polished Dark Mode support with high-contrast text and "Platinum/Gold" shimmer effects.
- **Animations**: Beautiful pulse animations, smooth page transitions, and interactive "Post-It" style dashboard widgets.
- **Shimmer Effects**: Premium gold shimmer on titles, buttons, and icons for a high-end feel.

### 3. 🔒 Advanced Security (App Lock)
- **Biometric Auth**: Secure your business data with Fingerprint, Face ID, or Iris scanning.
- **Device Fallback**: Seamlessly supports PIN/Pattern if biometrics are not enrolled.
- **Global Lock**: App automatically locks on startup and when resumed from background (>5 minutes).
- **Session Management**: Intelligent RAM-based session tracking ensures maximum security on cold starts.
- **Privacy Mode**: App content is hidden in the recent apps switcher.

### 4. 🌍 Global Localization
- **10+ Languages**: Full support for English, Malayalam, Hindi, Tamil, Spanish, French, Arabic, German, Indonesian, and Portuguese.
- **Dynamic Switching**: Instantly switch languages without restarting the app.
- **PDF Reports**: Generated PDF reports automatically respect the selected language.

### 5. 📊 Professional Reporting
- **PDF Generation**: Create detailed monthly income/expense reports.
- **Clean Layout**: Auto-adjusting columns based on business type.
- **Sharing**: One-tap sharing of reports via WhatsApp, Email, or Print.

### 6. 🛠 Tech Stack
- **Framework**: Flutter (v3.x)
- **Language**: Dart
- **Storage**: SharedPreferences & Local Storage (JSON)
- **Architecture**: Service-Oriented Architecture (SOA) with clean separation of UI and Logic.
- **Native Integration**: `FlutterFragmentActivity` for robust Android biometric support.

## 📦 Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/kiran-embedded/-vownote-app.git
   cd -vownote-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 📝 Patch Notes (v2.3.0)

**New Features:**
- **App Lock**: Added "Beautiful UI" Lock Screen with Gradients & Pulse animations. Fixed lifecycle issues ensuring reliable locking on resume.
- **Business Logic**: completely refactored booking engine to support non-wedding businesses.
- **Settings UI**: Redesigned settings with "Pill" layout and dynamic color integration.

**Fixes:**
- Fixed `NoFragmentActivity` crash by migrating to `FlutterFragmentActivity`.
- Fixed invisible text issues in Dark Mode.
- Fixed "Session Bypass" bug where app remained unlocked after restarting.

---
*Built with ❤️ by Kiran*
