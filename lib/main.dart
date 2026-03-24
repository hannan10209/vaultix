import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/new_lock_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  var onboardingDone = prefs.getBool('onboarding_completed') ?? false;

  if (!onboardingDone) {
    try {
      final perms = await const MethodChannel('com.vaultix.app/lock')
          .invokeMethod('checkPermissions');
      final permMap = Map<String, bool>.from(perms);
      if (permMap.isNotEmpty && permMap.values.every((v) => v == true)) {
        onboardingDone = true;
        await prefs.setBool('onboarding_completed', true);
      }
    } catch (_) {}
  }

  runApp(VaultixApp(onboardingDone: onboardingDone));
}

class VaultixApp extends StatelessWidget {
  final bool onboardingDone;

  const VaultixApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: onboardingDone ? '/home' : '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/new-lock',
          builder: (context, state) => const NewLockScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Vaultix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
