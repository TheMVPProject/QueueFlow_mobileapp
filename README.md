# QueueFlow Mobile App (Flutter)

## 🚀 Overview

QueueFlow Mobile App allows users to join a virtual queue, track their position in real time, and receive notifications when it’s their turn.

The app uses **state-driven navigation** and **real-time WebSocket updates** for a smooth user experience.

---

## 🧱 Tech Stack

* Flutter
* Riverpod (State Management)
* GoRouter (Navigation)
* WebSocket
* Firebase Messaging (FCM)
* Local Notifications

---

## 📱 Features

### User

* Login / Signup
* Join queue
* Real-time position updates
* Receive "Your Turn" notification
* 3-minute countdown timer
* Confirm presence

### Admin

* View full queue in real-time
* Call next user
* Remove users
* Pause / Resume queue

---

## 🔗 Backend Configuration

Update:

```
lib/config/api_config.dart
```

```dart
static const String baseUrl = 'https://YOUR-RAILWAY-URL.up.railway.app';
static const String wsUrl = 'wss://YOUR-RAILWAY-URL.up.railway.app/ws';
```

---

## ⚙️ Setup

```bash
git clone <repo>
cd QueueFlow_mobileapp
flutter pub get
```

Run:

```bash
flutter run
```

---

## 🔔 Notifications (FCM)

* Foreground → local notification shown
* Background → FCM handles delivery
* Tap notification → opens correct screen

---

## 🔁 Real-Time Updates

- WebSocket connection is established after login
- Automatic reconnection with exponential backoff
- UI updates instantly on incoming events

### Reconnection Behavior

- On reconnect:
  - WebSocket resumes listening to events
  - UI state is updated from latest broadcasts
  - Additional API sync can be triggered if needed

- Handles:
  - network loss
  - app background/foreground transitions

---

## 🔔 Notification Flow

- FCM is used for background and terminated state notifications
- Local notifications are shown in foreground

### Tap Handling

- When user taps notification:
  - App navigates to relevant screen (e.g., "Your Turn")
  - Navigation is state-driven using GoRouter
  - Queue state is validated before rendering screen

### Limitation

- Navigation may briefly delay if state is not yet synced after cold start

---

## 🧭 Navigation

* Managed using GoRouter
* Fully state-driven (no manual navigation)
* Routes:

  * Login
  * Queue Home
  * Queue Status
  * Your Turn
  * Admin Dashboard
* Navigation decisions are driven by queue state (e.g., auto-redirect to "Your Turn")
---

## 🧠 State Management

* AuthProvider → authentication
* QueueProvider → queue state
* WebSocketProvider → connection

---

## 🔄 Data Flow

- REST API is used for:
  - Authentication (login/signup)
  - Queue actions (join, leave, confirm)

- WebSocket is used for:
  - Real-time queue position updates
  - "Your Turn" events
  - Admin queue state updates

- Backend remains the **source of truth**
- Frontend reflects state based on:
  - WebSocket events
  - API responses
- UI never assumes state — always derived from backend events or API

---

## ⏱️ Countdown Logic

- Countdown is calculated using server-provided `timeoutAt`
- No reliance on client-side start time
- Recalculates on every screen rebuild and app resume
- Prevents timer drift and client-side manipulation

---

## 🛡️ Error Handling

- API errors are handled with user-friendly messages
- Network failures show retry options
- WebSocket disconnect triggers automatic reconnect
- Invalid states are prevented using guarded navigation logic

---

## 🔄 App Lifecycle Handling

- Detects app background and foreground transitions
- Reconnects WebSocket on app resume
- Recalculates countdown timer using server `timeoutAt`
- Ensures UI stays consistent after interruptions (calls, network switch)

This prevents stale UI and timer drift.

## ⚠️ Known Limitations

- Minor latency in navigation due to state-driven routing and async WebSocket synchronization
- Notification deep-linking can be improved for more deterministic routing
- App tested on Android devices and iOS simulator (not tested on physical iOS device)
- Edge cases may occur during rapid reconnect scenarios (network switching)
- UI can be further polished for production-level consistency

---

## 📌 What I Would Improve With More Time

* Better offline handling
* Enhanced UI/UX polish
* Improved notification routing reliability
* Add animations and transitions

---

## 🧪 Testing Checklist

* Login / Signup ✔
* Join queue ✔
* Live updates ✔
* Your turn flow ✔
* Timer accuracy ✔
* Admin controls ✔

---

## 📖 Notes

This app prioritizes:

* Real-time experience
* Clean navigation flow
* Reliable state handling
* Client acts as a reactive layer, while backend enforces all critical logic

---

## 👨‍💻 Author

mohidsk
