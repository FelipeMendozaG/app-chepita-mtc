import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'storage_service.dart';

class SessionManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> handleSessionExpired() async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      await ProviderScope.containerOf(
        context,
        listen: false,
      ).read(authStateProvider.notifier).logout();
    } else {
      await StorageService().clearSession();
    }

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
