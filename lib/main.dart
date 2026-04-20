import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/services/notification_service.dart';
import 'package:queueflow_mobileapp/services/fcm_service.dart';
import 'package:queueflow_mobileapp/features/auth/screens/login_screen.dart';
import 'package:queueflow_mobileapp/features/queue/screens/queue_home_screen.dart';
import 'package:queueflow_mobileapp/features/admin/screens/admin_dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize services
  await NotificationService().initialize();
  await FCMService().initialize();

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
    final websocketService = ref.read(websocketServiceProvider);

    if (authState.isAuthenticated) {
      switch (state) {
        case AppLifecycleState.resumed:
          // App came to foreground - reconnect WebSocket
          if (websocketService.currentStatus != ConnectionStatus.connected) {
            websocketService.connect(authState.user!.token);
          }
          break;
        case AppLifecycleState.paused:
          // App went to background - keep WebSocket connected
          // WebSocket will auto-reconnect if connection is lost
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
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'QueueFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: authState.isAuthenticated
          ? (authState.isAdmin
              ? const AdminDashboardScreen()
              : const QueueHomeScreen())
          : const LoginScreen(),
    );
  }
}
