import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/queue_provider.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';
import 'package:queueflow_mobileapp/widgets/connection_banner.dart';
import 'package:queueflow_mobileapp/widgets/primary_button.dart';
import 'package:queueflow_mobileapp/utils/app_snackbar.dart';

class YourTurnScreen extends ConsumerStatefulWidget {
  const YourTurnScreen({super.key});

  @override
  ConsumerState<YourTurnScreen> createState() => _YourTurnScreenState();
}

class _YourTurnScreenState extends ConsumerState<YourTurnScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _hasConfirmed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final queueState = ref.read(queueProvider);
    if (queueState.yourTurn != null) {
      // Use the backend-calculated remaining seconds for perfect sync
      _remainingSeconds = queueState.yourTurn!.timeoutInSeconds;

      if (_remainingSeconds <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppSnackbar.showWarning(
              context,
              'Confirmation time has expired',
            );
          }
        });
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds < 30) return AppTheme.errorColor;
    if (_remainingSeconds < 60) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  Color get _timerBackgroundColor {
    if (_remainingSeconds < 30) return AppTheme.errorLight;
    if (_remainingSeconds < 60) return AppTheme.warningLight;
    return AppTheme.successLight;
  }

  Future<void> _confirmTurn() async {
    if (_hasConfirmed) return;

    setState(() {
      _hasConfirmed = true;
    });

    await ref.read(queueProvider.notifier).confirmTurn();
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueProvider);

    // Listen for confirmation success
    ref.listen(queueProvider, (previous, next) {
      if (next.yourTurn == null &&
          previous?.yourTurn != null &&
          !next.hasTimedOut) {
        _timer?.cancel();

        if (mounted) {
          AppSnackbar.showSuccess(
            context,
            'Your presence has been confirmed',
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Turn!'),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Banner
          const ConnectionBanner(),

          // Main Content
          Expanded(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Icon
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.5 + (0.5 * value),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingXL),
                          decoration: BoxDecoration(
                            color: AppTheme.successLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 80,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXXL),

                      // Title
                      Text(
                        'It\'s Your Turn!',
                        style: AppTheme.displayLarge.copyWith(
                          color: AppTheme.successColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingLG),

                      // Subtitle
                      Text(
                        'Please confirm your presence within:',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingXXL),

                      // Countdown Timer Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _timerBackgroundColor,
                              _timerBackgroundColor.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _timerColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _timerColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _formattedTime,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _timerColor,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing3XL),

                      // Warning Message (if less than 1 minute)
                      if (_remainingSeconds < 60)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingLG),
                          margin: const EdgeInsets.only(
                            bottom: AppTheme.spacingXL,
                          ),
                          decoration: BoxDecoration(
                            color: _remainingSeconds < 30
                                ? AppTheme.errorLight
                                : AppTheme.warningLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                            border: Border.all(
                              color: _remainingSeconds < 30
                                  ? AppTheme.errorColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: _remainingSeconds < 30
                                    ? AppTheme.errorColor
                                    : AppTheme.warningColor,
                              ),
                              const SizedBox(width: AppTheme.spacingMD),
                              Expanded(
                                child: Text(
                                  _remainingSeconds < 30
                                      ? 'Hurry! Less than 30 seconds remaining!'
                                      : 'Less than 1 minute remaining!',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: _remainingSeconds < 30
                                        ? AppTheme.errorColor
                                        : AppTheme.warningColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Confirm Button
                      PrimaryButton(
                        text: 'Confirm My Presence',
                        icon: Icons.check_circle_rounded,
                        onPressed: _hasConfirmed || queueState.isLoading
                            ? null
                            : _confirmTurn,
                        isLoading: queueState.isLoading,
                        backgroundColor: AppTheme.successColor,
                      ),

                      const SizedBox(height: AppTheme.spacingLG),

                      // Info Text
                      if (!_hasConfirmed)
                        Text(
                          'Please confirm within 3 minutes or your slot will be reassigned',
                          style: AppTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
