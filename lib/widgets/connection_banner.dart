import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/websocket_provider.dart';
import 'package:queueflow_mobileapp/theme/app_theme.dart';

/// Shows WebSocket connection status banner
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(websocketStatusProvider);

    return connectionStatus.when(
      data: (status) {
        // Only show banner when reconnecting or disconnected
        if (status == ConnectionStatus.connected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: status == ConnectionStatus.reconnecting
              ? AppTheme.warningColor
              : AppTheme.errorColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG,
            vertical: AppTheme.spacingMD,
          ),
          child: Row(
            children: [
              if (status == ConnectionStatus.reconnecting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Text(
                  status == ConnectionStatus.reconnecting
                      ? 'Reconnecting to server...'
                      : 'Connection lost. Attempting to reconnect...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
