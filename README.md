# BizLedger (v2.3.4)

BizLedger is a high-performance business registry application designed for local persistence, offline independence, and sensory elegance.

---

## 📱 App Screenshot Gallery

<div align="center">

### Primary Viewports
<table>
  <tr>
    <td align="center" width="25%">
      <img src="docs/screenshots/01_home_dashboard.jpeg" width="180" alt="Home Dashboard"/>
      <br/><sub><b>🏠 Home Dashboard</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/02_bookings_detail.jpeg" width="180" alt="Bookings Detail Feed"/>
      <br/><sub><b>📄 Bookings Feed</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/03_calendar.jpeg" width="180" alt="Interactive Calendar"/>
      <br/><sub><b>📅 Events Calendar</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/04_insights_reports.jpeg" width="180" alt="Reports & Analytics"/>
      <br/><sub><b>📊 Financial Reports</b></sub>
    </td>
  </tr>
</table>

### Gestures & Security Guardrails
<table>
  <tr>
    <td align="center" width="25%">
      <img src="docs/screenshots/07_swipe_to_receive.jpeg" width="180" alt="Payment Confirmation Warning"/>
      <br/><sub><b>💸 Swipe to Receive Confirmation</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/08_bulk_delete.jpeg" width="180" alt="Bulk Selection Delete"/>
      <br/><sub><b>🗑️ Multi-Delete Overlay Bar</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/09_exit_warning.jpeg" width="180" alt="App Exit Confirmation Dialog"/>
      <br/><sub><b>🚪 Back-Press Exit Safe-Gate</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/13_biometric_lock.jpeg" width="180" alt="Biometric Lock Screen"/>
      <br/><sub><b>🔒 Secure Enclave Auth</b></sub>
    </td>
  </tr>
</table>

### Forms, Filters, & Configuration
<table>
  <tr>
    <td align="center" width="25%">
      <img src="docs/screenshots/05_settings.jpeg" width="180" alt="Settings Screen"/>
      <br/><sub><b>⚙️ Preferences & Cloud Sync</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/06_help_center.jpeg" width="180" alt="Collapsible Help Center"/>
      <br/><sub><b>📚 Help & Instructions Centre</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/10_advanced_filters.jpeg" width="180" alt="Advanced Multi-Filter Sheet"/>
      <br/><sub><b>🔍 Multi-Dimension Filters</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="docs/screenshots/11_booking_form_financial.jpeg" width="180" alt="Booking Creation Form"/>
      <br/><sub><b>💰 Booking Form Finances</b></sub>
    </td>
  </tr>
</table>

</div>

---

## 🏗️ Technical Architecture & Persistence Model

### 1. Unified SQLite Engine (SQL-JSON Hybrid)
* **Encrypted Storage**: Relies on `sqflite_sqlcipher` to implement hardware-accelerated local data encryption using an 256-bit AES cryptographic passkey.
* **ACID Transactions & WAL mode**: Configured with Write-Ahead Logging (`PRAGMA journal_mode = WAL;`) and relaxed synchronization (`PRAGMA synchronous = NORMAL;`) to ensure high-performance concurrent writes and reads without risking data corruption during interruptions.
* **Triple-Lock Local Backups**: The `BackupService` triggers a database copy to three distinct locations:
  1. Internal App Sandbox
  2. Public `/Documents/BizLedger/` folder for user accessibility
  3. External Shared Storage `/BizLedger/Backups/` to survive app uninstallation
* **WAL Checkpointing**: Before replication, the backup engine issues `PRAGMA wal_checkpoint(FULL);` to flush all transactional changes from the WAL log directly into the primary binary `.db` file, guaranteeing backup integrity.
* **Google Drive Integration**: Auto-synchronizes the encrypted database snapshot directly to the user's Google Drive appdata folder, keeping the user's data isolated and private.

---

## 🎨 User Interface & Navigation Evolution

The application navigation has been redesigned for a more seamless and intuitive experience.

```
OLD NAVIGATION MODEL (v2.3.2)
[ SliverAppBar (Top Calendar Icon + Top Settings Icon + Top Insight Icons) ]
                         │ (Taps trigger modals/pushes)
                         ▼
             [ Unified Dashboard List ]

NEW STATEFUL NAVIGATION MODEL (v2.3.4)
[ PageView (Horizontal Swipe / Navigation Controller) ]
  ├── 🏠 Home Dashboard (Stats Grid, Action Pills, Bookings Feed)
  ├── 📅 Events Calendar (Extracted Screen, Date-highlight grids)
  ├── 📊 Financial Reports (Analytics, Compact Valuation Indicators)
  └── ⚙️ System Settings (Biometrics, Cloud Sync, Version Check)
                         ▲
                         │ (Controlled by bottom viewport controller)
[ Animated Bottom Navigation Bar (Scale transitions & active glow overlays) ]
```

### 1. PageView Navigation & Bottom Bar
* **Old Structure**: Screens like the Calendar and Settings were pushed onto the navigation stack using icons pinned to the top header (`SliverAppBar` actions).
* **New Structure**: Replaced with an active `PageView` coupled with a custom, low-latency **Bottom Navigation Bar**. Selected tabs animate with custom scale transitions, active background glow boxes, and text state changes.

### 2. Multi-Pill Advanced Filters
* Tapping filter chips directly executes queries:
  * **This Month / Today / This Week**: Pre-calculates DateTime offsets to isolate bookings matching localized date lists.
  * **Payment Pills**: Segregates clients based on remaining balance calculations (`totalWithTax - advanceReceived`).
  * **Advanced Filter Engine**: Searches names, phone numbers, notes, locations, and booking IDs, and allows sorting by date, creation time, or invoice amount.

### 3. Dedicated Sub-Screens
* **`bookings_detail_screen.dart`**: Shows a pre-filtered list of bookings based on the clicked card, equipped with localized query states.
* **`calendar_screen.dart`**: Displays an interactive calendar with colored indicators showing bookings and events per day.

---

## 👆 Gestures & User Safeguards

### 1. Dual-Swipe List Operations
List items in `BookingsDetailScreen` are wrapped with a `Dismissible` widget supporting dual actions:
* **Swipe Right (→) to Share**: Fires `share_plus` to generate pre-formatted WhatsApp thank-you messages with client details.
* **Swipe Left (←) to Receive**: Triggers a confirmation bottom sheet. It presents a warning (*"This will mark the full pending amount as received. This cannot be undone easily."*), prompting verification to prevent accidental updates.

### 2. Selection Mode & Bulk Actions
* Long-pressing any card in the main dashboard activates **Selection Mode**.
* A persistent action bar slides up from the bottom showing the selection count along with `Cancel` and `Delete` actions.

### 3. Exit Protection
* Employs Flutter's `PopScope` to handle Android's system back button gestures:
  * If in Selection Mode, back press deselects items.
  * If on non-home tabs, back press returns to the Home dashboard page.
  * If on the Home page, back press prompts an exit confirmation dialog.

---

## 🛠️ Setup & Development

### Commands
```bash
# Get dependencies
flutter pub get

# Generate release APK
flutter build apk --release

# Sideload build
adb install build/app/outputs/flutter-apk/app-release.apk
```
