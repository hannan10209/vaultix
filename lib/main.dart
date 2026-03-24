import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/app_picker_screen.dart';
import 'screens/new_lock_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'services/lock_channel.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const VaultixApp());
}

class VaultixApp extends StatelessWidget {
  const VaultixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        if (state.matchedLocation == '/') {
          try {
            final perms = await LockChannel().checkPermissions();
            final allGranted = perms.values.every((v) => v == true);
            if (allGranted) return '/home';
          } catch (_) {}
        }
        return null;
      },
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
