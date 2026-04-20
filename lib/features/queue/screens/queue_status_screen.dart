import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/queue_provider.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/features/queue/screens/your_turn_screen.dart';
import 'package:queueflow_mobileapp/features/queue/screens/queue_home_screen.dart';
import 'package:queueflow_mobileapp/features/auth/screens/login_screen.dart';

class QueueStatusScreen extends ConsumerWidget {
  const QueueStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueProvider);

    // Navigate to your turn screen when called
    ref.listen(queueProvider, (previous, next) {
      if (next.yourTurn != null && previous?.yourTurn == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const YourTurnScreen()),
        );
      } else if (next.hasTimedOut && previous?.hasTimedOut != true) {
        // Show timeout dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Timeout'),
            content: const Text(
                'Your confirmation time has expired. You have been removed from the queue.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const QueueHomeScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (!next.inQueue && previous?.inQueue == true) {
        // Left queue, return to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QueueHomeScreen()),
        );
      }
    });

    if (!queueState.inQueue) {
      return const QueueHomeScreen();
    }

    final status = queueState.status!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Position',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${status.position}',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Total in queue: ${status.totalInQueue}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: status.isWaiting
                        ? Colors.orange[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.isWaiting ? Icons.hourglass_empty : Icons.check,
                        color: status.isWaiting ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status.isWaiting ? 'Waiting' : status.status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              status.isWaiting ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Please stay connected. You will be notified when it\'s your turn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: queueState.isLoading
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Leave Queue'),
                                content: const Text(
                                    'Are you sure you want to leave the queue?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      ref
                                          .read(queueProvider.notifier)
                                          .leaveQueue();
                                    },
                                    child: const Text('Leave'),
                                  ),
                                ],
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Leave Queue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
