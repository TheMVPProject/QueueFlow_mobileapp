# QueueFlow Mobile App

Flutter-based mobile application for the QueueFlow virtual queue system.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run app
flutter run
```

## Configuration

Update API endpoints in `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:8080';
static const String wsUrl = 'ws://localhost:8080/ws';
```

**Note**: For Android emulator, use `http://10.0.2.2:8080` instead of `localhost`.

## Features

### User Features
- Join virtual queue remotely
- Real-time position updates
- Turn notification with countdown timer
- 3-minute confirmation window
- App lifecycle management (background/foreground)

### Admin Features
- Real-time queue dashboard
- Call next user
- Remove users from queue
- Pause/resume queue operations

## Project Structure

```
queueflow_mobileapp/
├── lib/
│   ├── config/              # API configuration
│   ├── models/              # Data models
│   ├── services/            # API, WebSocket, storage services
│   ├── providers/           # Riverpod state management
│   ├── features/
│   │   ├── auth/            # Authentication screens
│   │   ├── queue/           # Queue user screens
│   │   └── admin/           # Admin dashboard
│   └── main.dart            # App entry point
└── pubspec.yaml
```

## State Management

Uses **Riverpod** for:
- Authentication state
- Queue status management
- Real-time WebSocket updates
- Admin queue management

## WebSocket Features

- Automatic reconnection with exponential backoff
- Connection status tracking
- Message event routing
- Background/foreground state handling

## Testing

Login with demo accounts:
- **Admin**: `admin` / `password123`
- **User**: `user1` / `password123`

## Deployment

For production:
1. Update `api_config.dart` with production backend URL
2. Build release:
   - iOS: `flutter build ios`
   - Android: `flutter build apk --release`

See main [README.md](../README.md) for comprehensive documentation.
