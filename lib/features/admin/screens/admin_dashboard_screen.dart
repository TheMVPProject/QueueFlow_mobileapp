import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/admin_provider.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';
import 'package:queueflow_mobileapp/widgets/connection_banner.dart';
import 'package:queueflow_mobileapp/utils/app_snackbar.dart';
import 'package:queueflow_mobileapp/utils/error_handler.dart';

/// Separate widget for countdown timer to avoid rebuilding entire screen
class _CountdownTimer extends StatefulWidget {
  final DateTime timeoutAt;

  const _CountdownTimer({required this.timeoutAt});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  Timer? _timer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now().toUtc();
    final timeout = widget.timeoutAt.toUtc();
    final remaining = timeout.difference(now).inSeconds;

    if (remaining <= 0) {
      setState(() => _remainingTime = '0:00');
    } else {
      final minutes = remaining ~/ 60;
      final seconds = remaining % 60;
      setState(() => _remainingTime = '$minutes:${seconds.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _remainingTime,
      style: AppTheme.bodySmall.copyWith(
        color: AppTheme.errorColor,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    // Listen for errors
    ref.listen(adminProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppSnackbar.showError(context, getErrorMessage(next.error!));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.adminColor,
        foregroundColor: Colors.white,
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

          // Admin Controls
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor,
                ),
              ),
            ),
            child: Column(
              children: [
                // Action Buttons Row
                Row(
                  children: [
                    // Call Next Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: adminState.isLoading ||
                                adminState.queue.isEmpty ||
                                (adminState.queue.length == 1 &&
                                    adminState.queue[0].status == 'called')
                            ? null
                            : () {
                                ref.read(adminProvider.notifier).callNext();
                                AppSnackbar.showSuccess(
                                  context,
                                  'Called next user',
                                );
                              },
                        icon: const Icon(Icons.forward_rounded, size: 20),
                        label: const Text('Call Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingLG,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppTheme.spacingMD),

                    // Pause/Resume Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: adminState.isLoading
                            ? null
                            : () {
                                if (adminState.isPaused) {
                                  ref
                                      .read(adminProvider.notifier)
                                      .resumeQueue();
                                  AppSnackbar.showSuccess(
                                    context,
                                    'Queue resumed',
                                  );
                                } else {
                                  ref.read(adminProvider.notifier).pauseQueue();
                                  AppSnackbar.showInfo(
                                    context,
                                    'Queue paused',
                                  );
                                }
                              },
                        icon: Icon(
                          adminState.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 20,
                        ),
                        label: Text(adminState.isPaused ? 'Resume' : 'Pause'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: adminState.isPaused
                              ? AppTheme.primaryColor
                              : AppTheme.warningColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingLG,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Paused Status Banner
                if (adminState.isPaused) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      border: Border.all(color: AppTheme.warningColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pause_circle_rounded,
                          color: AppTheme.warningColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: Text(
                            'Queue is paused',
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Queue Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Queue',
                  style: AppTheme.headlineMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                    vertical: AppTheme.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '${adminState.queue.length} ${adminState.queue.length == 1 ? 'user' : 'users'}',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Queue List
          Expanded(
            child: adminState.isLoading && adminState.queue.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : adminState.queue.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Queue auto-updates via WebSocket
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingXL,
                          ),
                          itemCount: adminState.queue.length,
                          itemBuilder: (context, index) {
                            final entry = adminState.queue[index];
                            final isCalled = entry.status == 'called';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingLG,
                                vertical: AppTheme.spacingSM,
                              ),
                              decoration: BoxDecoration(
                                color: isCalled
                                    ? AppTheme.successLight
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMD,
                                ),
                                border: Border.all(
                                  color: isCalled
                                      ? AppTheme.successColor
                                      : AppTheme.borderColor,
                                  width: isCalled ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingLG,
                                  vertical: AppTheme.spacingSM,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isCalled
                                          ? [
                                              AppTheme.successColor,
                                              AppTheme.successColor
                                                  .withValues(alpha: 0.8),
                                            ]
                                          : [
                                              AppTheme.primaryColor,
                                              AppTheme.primaryLight,
                                            ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.position}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  entry.username ?? 'User ${entry.userId}',
                                  style: AppTheme.titleMedium,
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      isCalled
                                          ? Icons.notifications_active_rounded
                                          : Icons.hourglass_empty_rounded,
                                      size: 14,
                                      color: isCalled
                                          ? AppTheme.successColor
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: AppTheme.spacingSM),
                                    Text(
                                      isCalled ? 'Called' : 'Waiting',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: isCalled
                                            ? AppTheme.successColor
                                            : AppTheme.textSecondary,
                                        fontWeight: isCalled
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    // Show timer for called users
                                    if (isCalled && entry.timeoutAt != null) ...[
                                      const SizedBox(width: AppTheme.spacingMD),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingSM,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorLight,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSM,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.errorColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.timer_rounded,
                                              size: 12,
                                              color: AppTheme.errorColor,
                                            ),
                                            const SizedBox(width: 4),
                                            _CountdownTimer(timeoutAt: entry.timeoutAt!),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppTheme.errorColor,
                                  ),
                                  onPressed: () {
                                    _showRemoveUserDialog(
                                      context,
                                      ref,
                                      entry.userId,
                                      entry.username ?? 'this user',
                                    );
                                  },
                                  tooltip: 'Remove user',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXXL),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 64,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Text(
            'No users in queue',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'Users will appear here when they join',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showRemoveUserDialog(
    BuildContext context,
    WidgetRef ref,
    int userId,
    String username,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Remove $username from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(adminProvider.notifier).removeUser(userId);
              AppSnackbar.showSuccess(
                context,
                'User removed from queue',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
