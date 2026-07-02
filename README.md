# BizLedger

BizLedger is a dynamic, high-fidelity business manager built with Flutter and SQLite. This documentation outlines the design shift and structural changes introduced in **v2.3.4** compared to the older versions.

---

## 🆚 Design Evolution: Old vs New UI

### 1. Navigation Flow
* **Old Version**: Navigation was driven entirely by top icons inside the `SliverAppBar` actions list (e.g. settings icon, calendar icon, and business insight buttons located at the top).
* **New Version (v2.3.4)**: Replaced top header icons with a swipeable `PageView` managed by a custom, animated **Bottom Navigation Bar**. This includes premium icon transitions (scale-up, fade-in, active glow) to navigate smoothly between:
  * 🏠 **Home** (Dashboard)
  * 📅 **Calendar** (Dedicated screen)
  * 📊 **Reports** (Analytics)
  * ⚙️ **Settings** (App preferences)

### 2. Search & Filtering System
* **Old Version**: Standard list view with basic search and minimal grouping.
* **New Version (v2.3.4)**: Integrated a dynamic pill-based filtering system at the top of the dashboard:
  * **📅 This Month**: Filters events in the current month (with dropdown options for Today, This Week, Last Month, Custom Range).
  * **👤 Client**: Dynamic filter sheet to filter bookings by client.
  * **💰 Payment**: Filter by payment status (Paid, Advance, Due, Upcoming, Cancelled).
  * **⚙️ More Filters**: Opens a premium sheet for multi-dimensional filters (Service Type, Location worldwide, Amount ranges, and Sorting).
  * **🔍 Comprehensive Search Engine**: Searches not just names, but also email, phone, location, event type, and booking IDs.

### 3. File and Layout Restructuring
* **`lib/ui/home_screen.dart`**: Rewritten from a single page setup to host the primary tab controller, stats grid, and bottom navigation bar.
* **`lib/ui/bookings_detail_screen.dart` (NEW File)**: Added as a dedicated sub-screen loaded when tapping stats cards (Active Bookings, Pending Amount, Completed). Features bidirectional swiping:
  * **Swipe Right (→)**: Share thank-you messages directly to WhatsApp with haptics.
  * **Swipe Left (←)**: Marks pending amounts as fully received after confirming a warning bottom sheet.
* **`lib/ui/calendar_screen.dart` (NEW File)**: Extracted into a dedicated screen for managing events by date with high-contrast indicator dots.
* **`lib/ui/help_center_screen.dart`**: Fully redesigned into a premium AMOLED-dark layout with quick-search, collapsible guides with step-by-step numbers, and user feedback buttons.
* **`lib/ui/settings_screen.dart`**: Cleaned up layout to run strictly in dark mode, removing the obsolete light/dark appearance switches.

---

## 🛠️ Key Technical Additions in v2.3.4

* **Exit Protection**: Integrated `PopScope` on the home screen to prevent accidental app closes. Pressing the system back button displays a custom exit confirmation dialog.
* **Dynamic Greetings**: Replaced hardcoded "Kiran" greeting with dynamic username fetching from the signed-in Google account (`GoogleDriveService`), falling back to "Guest" for local-only setups.
* **Compact Layouts**: Changed large currency numbers on stat widgets to use compact formats (e.g. `₹365K` instead of `₹365,000`) to guarantee compatibility across small and large phone screens.
* **Haptics integration**: Handled confirmation actions, page transitions, and selection toggles with distinct vibration patterns.

---

## 📦 Getting Started

### Prerequisites
- Flutter SDK: `3.27.0+`
- Dart SDK: `3.0.0+`
- SQLite environment

### Build & Run
```bash
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```
