import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queueflow_mobileapp/providers/queue_provider.dart';
import 'package:queueflow_mobileapp/providers/auth_provider.dart';
import 'package:queueflow_mobileapp/features/queue/screens/queue_home_screen.dart';
import 'package:queueflow_mobileapp/features/auth/screens/login_screen.dart';

class YourTurnScreen extends ConsumerStatefulWidget {
  const YourTurnScreen({super.key});

  @override
  ConsumerState<YourTurnScreen> createState() => _YourTurnScreenState();
}

class _YourTurnScreenState extends ConsumerState<YourTurnScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;

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
      _remainingSeconds = queueState.yourTurn!.timeoutAt
          .difference(DateTime.now())
          .inSeconds;

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

  void _confirmTurn() {
    ref.read(queueProvider.notifier).confirmTurn();
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueProvider);

    // Navigate away when confirmed or timed out
    ref.listen(queueProvider, (previous, next) {
      if (next.isConfirmed && previous?.isConfirmed != true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmed'),
            content: const Text('Your turn has been confirmed successfully!'),
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
      } else if (next.hasTimedOut && previous?.hasTimedOut != true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QueueHomeScreen()),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Turn!'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                const Icon(
                  Icons.notifications_active,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 32),
                const Text(
                  'It\'s Your Turn!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please confirm your presence within:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 60
                        ? Colors.red[50]
                        : Colors.green[50],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _remainingSeconds < 60
                          ? Colors.red
                          : Colors.green,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds < 60
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: queueState.isLoading ? null : _confirmTurn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: queueState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm My Presence',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_remainingSeconds < 60)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Less than 1 minute remaining!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
