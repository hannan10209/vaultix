import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/app_picker_screen.dart';
import 'screens/new_lock_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'services/lock_channel.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
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
          path: '/app-picker',
          builder: (context, state) => const AppPickerScreen(),
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
