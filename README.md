# VowNote - Professional Wedding Management

**VowNote** is a premium, iOS-aesthetics inspired wedding management application built with Flutter. Designed for professionals, it offers a seamless ("Apple Notes" style) experience for tracking booking details, financials, and generating high-quality reports.

> **Professional Version v2.0**
> (c) 2026 kiran-embedded | [GitHub Profile](https://github.com/kiran-embedded)

---

## 📱 Features

### 🎨 Professional iOS Design
- **True Black Dark Mode**: Optimized for OLED screens with "Apple Notes" dark gray cards.
- **Glassmorphism & Blurs**: High-performance UI with `BackdropFilter` and native transitions.
- **Haptic Feedback**: Subtle, premium tactile feedback on interactions.
- **Instant Launch**: No splash screen delays, instant access to your data.

### 💼 Smart Management
- **Booking Tracking**: Manage Bride/Groom details, multiple event dates, and full contact info.
- **Auto-Completion**: Intelligently marks past weddings as "Completed" with visual indicators.
- **Smart Search**: Fuzzy search logic to find clients instantly.
- **Multi-Select**: Long-press to batch delete or manage bookings.

### 💰 Financial Tracking
- **Advance vs. Received**: Separately track initial advances and total received payments.
- **Pending Calculation**: Auto-calc "Due" amounts with distinct color coding (Green/Red).

### 📄 Professional Exports
- **PDF Reports**: Generate monthly reports with detailed columns (Dates, Address, Financial Breakdown).
  - *Includes Professional Watermark & Branding.*
- **Shareable Cards**: Render booking details into beautiful images for WhatsApp sharing.
- **Text Share**: One-tap text summary formatted for professional communication.

### 🔒 Data Safety & Persistence
- **Global Backups**: Exports data to your `Documents/VowNote` folder to survive app uninstalls.
- **Simplified Restore**: Easy import/export JSON flow (no complex cloud setup required).

---

## 🛠 Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: `setState` & `ValueNotifier` (Clean Architecture)
- **Local Database**: `sqflite`
- **PDF Generation**: `pdf` & `printing`
- **Notifications**: `flutter_local_notifications` + `timezone`
- **Permissions**: `permission_handler`

---

## 🚀 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/kiran-embedded/-vownote-app.git
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run --release
    ```

---

## 📸 Screenshots

*(Add your screenshots here)*

---

## 📜 License

Copyright © 2026 [kiran-embedded](https://github.com/kiran-embedded). All rights reserved.
Start managing weddings like a pro.
