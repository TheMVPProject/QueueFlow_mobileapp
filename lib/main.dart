import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/services/fcm_service.dart';
import 'package:queueflow_mobileapp/services/navigation_service.dart';
import 'package:queueflow_mobileapp/config/router.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';
import 'firebase_options.dart';

// Track app start time to allow WebSocket to connect before router redirects
final appStartTime = DateTime.now();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // NOTE: NotificationService and FCM will be initialized AFTER login
  // This prevents requesting notification permission before user is logged in

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔄 NEW: Mark router as ready after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService().markRouterReady();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final authState = ref.read(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final websocketService = ref.read(websocketServiceProvider);

    if (authState.isAuthenticated) {
      switch (state) {
        case AppLifecycleState.resumed:
          // Reconnect WebSocket if disconnected
          if (websocketService.currentStatus != ConnectionStatus.connected) {
            websocketService.connect(authState.user!.token);
          }

          // Refresh FCM token (in case permission was granted or token changed)
          authNotifier.refreshFCMToken();
          break;
        case AppLifecycleState.paused:
          // Keep WebSocket connected - will auto-reconnect if connection is lost
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'QueueFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
