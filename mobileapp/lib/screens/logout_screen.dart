import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Out')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 48),
              const SizedBox(height: 12),
              const Text('Are you sure you want to sign out?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _signOut(context),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
