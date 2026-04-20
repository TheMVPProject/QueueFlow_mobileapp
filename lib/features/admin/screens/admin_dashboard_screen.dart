import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/admin_provider.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/features/auth/screens/login_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
        child: Column(
          children: [
            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: adminState.isLoading ||
                                  adminState.queue.isEmpty
                              ? null
                              : () {
                                  ref.read(adminProvider.notifier).callNext();
                                },
                          icon: const Icon(Icons.forward),
                          label: const Text('Call Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: adminState.isLoading
                              ? null
                              : () {
                                  if (adminState.isPaused) {
                                    ref
                                        .read(adminProvider.notifier)
                                        .resumeQueue();
                                  } else {
                                    ref
                                        .read(adminProvider.notifier)
                                        .pauseQueue();
                                  }
                                },
                          icon: Icon(
                              adminState.isPaused ? Icons.play_arrow : Icons.pause),
                          label: Text(
                              adminState.isPaused ? 'Resume' : 'Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                adminState.isPaused ? Colors.blue : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (adminState.isPaused)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pause_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Queue is paused',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Queue list
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Queue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${adminState.queue.length} users',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Queue entries
            Expanded(
              child: adminState.isLoading && adminState.queue.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : adminState.queue.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No users in queue',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            // Queue auto-updates via WebSocket
                          },
                          child: ListView.builder(
                            itemCount: adminState.queue.length,
                            itemBuilder: (context, index) {
                              final entry = adminState.queue[index];
                              final isCalled = entry.status == 'called';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: isCalled ? Colors.green[50] : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCalled
                                        ? Colors.green
                                        : Colors.blue,
                                    foregroundColor: Colors.white,
                                    child: Text('${entry.position}'),
                                  ),
                                  title: Text(
                                    entry.username ?? 'User ${entry.userId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isCalled ? 'Called' : 'Waiting',
                                    style: TextStyle(
                                      color:
                                          isCalled ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove User'),
                                          content: Text(
                                              'Remove ${entry.username ?? 'this user'} from the queue?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                ref
                                                    .read(adminProvider.notifier)
                                                    .removeUser(entry.userId);
                                              },
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            if (adminState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red[50],
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        adminState.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        ref.read(adminProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
