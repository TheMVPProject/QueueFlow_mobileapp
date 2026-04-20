import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:queueflow_mobileapp/utils/logger.dart';

/// Global navigation service for handling navigation from anywhere
/// Useful for FCM notifications, deep links, etc.
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Store pending navigation from notification tap
  String? _pendingRoute;
  Map<String, dynamic>? _pendingData;
  final List<Function()> _pendingNavigations = [];

  // Router ready flag
  bool _isRouterReady = false;
  final Completer<void> _routerReadyCompleter = Completer<void>();

  /// Mark router as ready (call this after first frame or when router initializes)
  void markRouterReady() {
    if (!_isRouterReady) {
      AppLogger.success('Router marked as ready', 'Navigation');
      _isRouterReady = true;
      _routerReadyCompleter.complete();
      _executePendingNavigations();
    }
  }

  /// Wait for router to be ready
  Future<void> waitForRouter() async {
    if (_isRouterReady) return;
    AppLogger.info('Waiting for router to be ready', 'Navigation');
    await _routerReadyCompleter.future;
  }

  /// Set pending route to navigate to when app is ready
  void setPendingRoute(String route, {Map<String, dynamic>? data}) {
    AppLogger.debug('Storing pending route: $route', 'Navigation');
    _pendingRoute = route;
    _pendingData = data;
  }

  /// Get and clear pending route
  String? getPendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    _pendingData = null;
    return route;
  }

  /// Check if there's a pending route
  bool get hasPendingRoute => _pendingRoute != null;

  /// Navigate to a route by path (waits for router if needed)
  Future<void> navigateTo(String route, {Object? extra}) async {
    if (!_isRouterReady) {
      AppLogger.info('Router not ready, queueing navigation to: $route', 'Navigation');
      _pendingNavigations.add(() => _doNavigate(route, extra: extra));
      return;
    }

    await _doNavigate(route, extra: extra);
  }

  Future<void> _doNavigate(String route, {Object? extra}) async {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      AppLogger.success('Navigating to: $route', 'Navigation');
      context.go(route, extra: extra);
    } else {
      AppLogger.warning('No context available for navigation', 'Navigation');
      // Retry after delay if context not available
      await Future.delayed(const Duration(milliseconds: 500));
      final retryContext = navigatorKey.currentContext;
      if (retryContext != null && retryContext.mounted) {
        AppLogger.success('Retry successful, navigating to: $route', 'Navigation');
        retryContext.go(route, extra: extra);
      } else {
        AppLogger.error('Retry failed, storing as pending route', null, null, 'Navigation');
        setPendingRoute(route);
      }
    }
  }

  /// Execute all pending navigations
  void _executePendingNavigations() {
    if (_pendingNavigations.isEmpty) return;

    AppLogger.info('Executing ${_pendingNavigations.length} pending navigations', 'Navigation');
    for (final navigation in _pendingNavigations) {
      navigation();
    }
    _pendingNavigations.clear();
  }

  /// Push a route (adds to navigation stack)
  void pushTo(String route, {Object? extra}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      context.push(route, extra: extra);
    } else {
      AppLogger.warning('No context available for navigation', 'Navigation');
    }
  }

  /// Go back
  void goBack() {
    final context = navigatorKey.currentContext;
    if (context != null && context.canPop()) {
      context.pop();
    }
  }

  /// Handle notification tap navigation (queues if router not ready)
  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    AppLogger.info('Handling notification tap: $data', 'Navigation');

    final type = data['type'];

    switch (type) {
      case 'your_turn':
        AppLogger.info('Notification type: your_turn', 'Navigation');
        await navigateTo('/your-turn');
        break;

      case 'position_update':
        AppLogger.info('Notification type: position_update', 'Navigation');
        await navigateTo('/queue/status');
        break;

      case 'user_joined':
        AppLogger.info('Notification type: user_joined (admin)', 'Navigation');
        await navigateTo('/admin');
        break;

      default:
        AppLogger.warning('Unknown notification type: $type', 'Navigation');
        await navigateTo('/queue/status');
    }
  }
}
