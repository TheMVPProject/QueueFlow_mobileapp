import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/providers/queue_provider.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';
import 'package:queueflow_mobileapp/widgets/primary_button.dart';
import 'package:queueflow_mobileapp/widgets/connection_banner.dart';
import 'package:queueflow_mobileapp/utils/app_snackbar.dart';
import 'package:queueflow_mobileapp/utils/error_handler.dart';

class QueueHomeScreen extends ConsumerWidget {
  const QueueHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final queueState = ref.watch(queueProvider);

    // Listen for errors
    ref.listen(queueProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppSnackbar.showError(context, getErrorMessage(next.error!, context: 'queue'));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueFlow'),
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
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXXL),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXXL),

                      // Welcome Message
                      Text(
                        'Welcome, ${authState.user?.username ?? 'User'}!',
                        style: AppTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacingLG),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: Text(
                                'Join the virtual queue and we\'ll notify you when it\'s your turn.',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacing3XL),

                      // Join Queue Button
                      PrimaryButton(
                        text: 'Join Queue',
                        icon: Icons.add_rounded,
                        onPressed: queueState.isLoading
                            ? null
                            : () {
                                ref.read(queueProvider.notifier).joinQueue();
                              },
                        isLoading: queueState.isLoading,
                      ),

                      const SizedBox(height: AppTheme.spacingXL),

                      // Additional Info
                      Text(
                        'You are not currently in the queue',
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
