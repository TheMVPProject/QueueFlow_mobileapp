import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queueflow_mobileapp/features/splash/splash_screen.dart';
import 'package:queueflow_mobileapp/features/auth/screens/auth_selection_screen.dart';
import 'package:queueflow_mobileapp/features/auth/screens/login_screen.dart';
import 'package:queueflow_mobileapp/features/auth/screens/register_screen.dart';
import 'package:queueflow_mobileapp/features/queue/screens/queue_home_screen.dart';
import 'package:queueflow_mobileapp/features/queue/screens/queue_status_screen.dart';
import 'package:queueflow_mobileapp/features/queue/screens/your_turn_screen.dart';
import 'package:queueflow_mobileapp/features/admin/screens/admin_dashboard_screen.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/queue_provider.dart';
import 'package:queueflow_mobileapp/services/navigation_service.dart';

/// Route names for easy navigation
class Routes {
  static const splash = '/';
  static const authSelection = '/auth';
  static const login = '/login';
  static const register = '/register';
  static const queueHome = '/queue';
  static const queueStatus = '/queue/status';
  static const yourTurn = '/your-turn';
  static const adminDashboard = '/admin';
}

/// A ChangeNotifier that fires when auth or queue state changes,
/// so GoRouter re-runs its redirect WITHOUT being recreated.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(queueProvider, (_, __) => notifyListeners());
  }
}

/// GoRouter provider — created ONCE, refreshed via notifier
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: NavigationService().navigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Read current state at redirect time (not captured in closure)
      final authState = ref.read(authProvider);
      final queueState = ref.read(queueProvider);

      final isInitialized = authState.isInitialized;
      final isAuthenticated = authState.isAuthenticated;
      final isAdmin = authState.isAdmin;
      final currentLocation = state.matchedLocation;

      // Allow access to auth screens when not authenticated
      final authScreens = [Routes.authSelection, Routes.login, Routes.register];

      // 1. Redirect from splash ONLY (never redirect back to splash)
      if (currentLocation == Routes.splash) {
        // Stay on splash while initializing
        if (!isInitialized) {
          return null;
        }
        // Initialized - redirect based on auth state
        if (isAuthenticated) {
          // User has stored token
          if (isAdmin) return Routes.adminDashboard;
          // Regular user
          if (queueState.yourTurn != null) return Routes.yourTurn;
          if (queueState.inQueue) return Routes.queueStatus;
          return Routes.queueHome;
        } else {
          // No stored token
          return Routes.authSelection;
        }
      }

      // 2. Auth check — must be logged in
      if (!isAuthenticated && !authScreens.contains(currentLocation)) {
        return Routes.authSelection;
      }

      // 3. If authenticated and on auth screen, redirect based on role
      if (isAuthenticated && authScreens.contains(currentLocation)) {
        if (isAdmin) return Routes.adminDashboard;
        // Regular user
        if (queueState.yourTurn != null) return Routes.yourTurn;
        if (queueState.inQueue) return Routes.queueStatus;
        return Routes.queueHome;
      }

      // 4. Admin routing
      if (isAuthenticated && isAdmin) {
        if (currentLocation != Routes.adminDashboard) {
          return Routes.adminDashboard;
        }
        return null;
      }

      // 5. Regular user routing based on queue state
      if (isAuthenticated && !isAdmin) {
        // It's your turn — always go to your turn screen
        if (queueState.yourTurn != null && currentLocation != Routes.yourTurn) {
          return Routes.yourTurn;
        }

        // Timed out or left queue — go home
        if ((queueState.hasTimedOut || !queueState.inQueue) &&
            (currentLocation == Routes.queueStatus || currentLocation == Routes.yourTurn)) {
          return Routes.queueHome;
        }

        // In queue but not your turn — should be on queue status
        if (queueState.inQueue && queueState.yourTurn == null && currentLocation == Routes.queueHome) {
          return Routes.queueStatus;
        }
      }

      return null; // stay on current page
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: Routes.authSelection,
        name: 'authSelection',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AuthSelectionScreen(),
        ),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: Routes.queueHome,
        name: 'queueHome',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const QueueHomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.queueStatus,
        name: 'queueStatus',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const QueueStatusScreen(),
        ),
      ),
      GoRoute(
        path: Routes.yourTurn,
        name: 'yourTurn',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const YourTurnScreen(),
          slideDirection: SlideDirection.up,
        ),
      ),
      GoRoute(
        path: Routes.adminDashboard,
        name: 'adminDashboard',
        pageBuilder: (context, state) => _buildPageWithSlideTransition(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        ),
      ),
    ],
  );
});

/// Slide direction for page transitions
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Build a page with slide transition animation
CustomTransitionPage _buildPageWithSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  SlideDirection slideDirection = SlideDirection.left,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Define slide offset based on direction
      Offset begin;
      switch (slideDirection) {
        case SlideDirection.left:
          begin = const Offset(1.0, 0.0);
          break;
        case SlideDirection.right:
          begin = const Offset(-1.0, 0.0);
          break;
        case SlideDirection.up:
          begin = const Offset(0.0, 1.0);
          break;
        case SlideDirection.down:
          begin = const Offset(0.0, -1.0);
          break;
      }

      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );

      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}
