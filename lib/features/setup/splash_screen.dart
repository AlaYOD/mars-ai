import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final String message;
  const SplashScreen({super.key, this.message = 'Starting Mars…'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.deepPurpleAccent,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'MARS AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
