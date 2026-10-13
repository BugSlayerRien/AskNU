import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/faq_service.dart';
import '../services/auth_service.dart';
import '../screens/landing_screen.dart';
import '../screens/sign_in.dart';

class AuthGate extends StatelessWidget {
  final FAQService service;
  const AuthGate({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        
        // If no user, show sign in screen
        if (user == null) {
          return const SignInScreen();
        }

        // User is authenticated - show landing screen immediately
        // Admin check happens inside LandingScreen or when needed
        return LandingScreen(service: service);
      },
    );
  }
}