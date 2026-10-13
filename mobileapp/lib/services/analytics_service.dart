import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logSignIn({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logBookmark({required String id, required String title, required bool added}) async {
    await _analytics.logEvent(name: 'bookmark', parameters: {'id': id, 'title': title, 'added': added});
  }
}
