import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'widgets/auth_gate.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in.dart';
import 'screens/sign_up.dart';
import 'screens/forgot_password.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/search_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/admin/admin_faqs_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/offices_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/notifications_management_screen.dart';
import 'screens/admin/audit_logs_screen.dart';
import 'screens/admin/analytics_screen.dart' as admin_analytics;
import 'screens/admin/settings_screen.dart' as admin_settings;
import 'services/faq_service.dart';
import 'services/app_settings_service.dart';
import 'screens/about_screen.dart';
import 'screens/logout_screen.dart';
import 'screens/document_requests_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppSettingsService.instance.load();
  runApp(const AskNUApp());
}

class AskNUApp extends StatelessWidget {
  const AskNUApp({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FAQService(remoteUrl: null);
    final settings = AppSettingsService.instance;

    final royalBlue = const Color(0xFF0A3D91);
    final gold = const Color(0xFFD4AF37);

    final scheme = ColorScheme.fromSeed(seedColor: royalBlue, primary: royalBlue, secondary: gold);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: royalBlue,
      scaffoldBackgroundColor: Colors.grey[50],
      fontFamily: 'CenturyGothic',
      appBarTheme: AppBarTheme(
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: royalBlue, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withAlpha((0.08 * 255).round()),
        labelStyle: TextStyle(color: scheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey[900]),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[900]),
        bodyLarge: TextStyle(fontSize: 15, color: Colors.grey[800]),
      ),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        for (var platform in TargetPlatform.values) platform: const FadeUpwardsPageTransitionsBuilder(),
      }),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: royalBlue, brightness: Brightness.dark, primary: royalBlue, secondary: gold),
      primaryColor: royalBlue,
      fontFamily: 'CenturyGothic',
      appBarTheme: AppBarTheme(
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: royalBlue, width: 2),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        for (var platform in TargetPlatform.values) platform: const FadeUpwardsPageTransitionsBuilder(),
      }),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AskNU',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          home: SplashScreen(next: AuthGate(service: service)),
          routes: {
            '/home': (_) => LandingScreen(service: service),
            '/sign-in': (_) => const SignInScreen(),
            '/sign-up': (_) => const SignUpScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/about': (_) => const AboutScreen(),
            '/logout': (_) => const LogoutScreen(),
            '/document-requests': (_) => const DocumentRequestsScreen(),
            '/admin/settings': (_) => const admin_settings.SettingsScreen(),
            '/categories': (_) => CategoriesScreen(service: service),
            '/offices': (_) => const OfficesScreen(),
            '/search': (_) => const SearchScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/admin/faqs': (_) => const AdminFaqsScreen(),
            '/admin/users': (_) => const AdminUsersScreen(),
            '/admin/dashboard': (_) => AdminDashboardScreen(service: service),
            '/admin/notifications': (_) => const NotificationsManagementScreen(),
            '/admin/audit-logs': (_) => const AuditLogsScreen(),
            '/conversations': (_) => const ConversationsScreen(),
            '/analytics': (_) => const AnalyticsScreen(),
            '/admin/analytics': (_) => const admin_analytics.AnalyticsScreen(),
          },
        );
      },
    );
  }
}