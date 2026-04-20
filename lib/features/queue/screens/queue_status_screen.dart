import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/queue_provider.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';
import 'package:queueflow_mobileapp/widgets/connection_banner.dart';
import 'package:queueflow_mobileapp/utils/app_snackbar.dart';

class QueueStatusScreen extends ConsumerWidget {
  const QueueStatusScreen({super.key});

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('not in queue')) {
      return 'You are not in the queue';
    }

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    return 'An error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueProvider);

    // Listen for errors
    ref.listen(queueProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppSnackbar.showError(context, _getErrorMessage(next.error!));
      }

      // Show timeout message
      if (next.hasTimedOut && previous?.hasTimedOut != true) {
        AppSnackbar.showWarning(
          context,
          'Your confirmation time expired',
        );
      }
    });

    final status = queueState.status;
    if (status == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        automaticallyImplyLeading: false,
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
                      // Position Circle with Animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                                AppTheme.primaryLight.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Position',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingSM),
                                Text(
                                  '${status.position}',
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXXL),

                      // Total in Queue
                      Text(
                        'Total in queue: ${status.totalInQueue}',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingLG),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLG,
                          vertical: AppTheme.spacingMD,
                        ),
                        decoration: BoxDecoration(
                          color: status.isWaiting
                              ? AppTheme.warningColor.withValues(alpha: 0.1)
                              : AppTheme.successLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: status.isWaiting
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status.isWaiting
                                  ? Icons.hourglass_empty_rounded
                                  : Icons.check_circle_rounded,
                              color: status.isWaiting
                                  ? AppTheme.warningColor
                                  : AppTheme.successColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingSM),
                            Text(
                              status.isWaiting ? 'Waiting' : status.status,
                              style: AppTheme.labelLarge.copyWith(
                                color: status.isWaiting
                                    ? AppTheme.warningColor
                                    : AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing3XL),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: Text(
                                'Please stay connected. You will be notified when it\'s your turn.',
                                style: AppTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXXL),

                      // Leave Queue Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: queueState.isLoading
                              ? null
                              : () {
                                  _showLeaveQueueDialog(context, ref);
                                },
                          icon: const Icon(Icons.exit_to_app_rounded),
                          label: const Text('Leave Queue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(
                              color: AppTheme.errorColor,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingLG,
                            ),
                          ),
                        ),
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

  void _showLeaveQueueDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Queue'),
        content: const Text(
          'Are you sure you want to leave the queue? You will lose your position.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(queueProvider.notifier).leaveQueue();
              AppSnackbar.showSuccess(context, 'Left queue successfully');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
