import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lock_channel.dart';

class _PermissionStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final String permissionKey;
  final Future<void> Function(LockChannel) request;

  const _PermissionStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.permissionKey,
    required this.request,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final _lockChannel = LockChannel();
  Map<String, bool> _permissions = {};

  final List<_PermissionStep> _steps = [
    _PermissionStep(
      title: 'Usage Access',
      subtitle: 'Lets Vaultix detect which app is in the foreground',
      icon: Icons.bar_chart,
      permissionKey: 'usageStats',
      request: (ch) => ch.requestUsageStatsPermission(),
    ),
    _PermissionStep(
      title: 'Accessibility Service',
      subtitle: 'Required to intercept and block app launches',
      icon: Icons.accessibility_new,
      permissionKey: 'accessibility',
      request: (ch) => ch.requestAccessibilityPermission(),
    ),
    _PermissionStep(
      title: 'Display Over Other Apps',
      subtitle: 'Required to show the lock screen over blocked apps',
      icon: Icons.layers,
      permissionKey: 'overlay',
      request: (ch) => ch.requestOverlayPermission(),
    ),
    _PermissionStep(
      title: 'Device Administrator',
      subtitle:
          'Prevents Vaultix from being uninstalled during a hard lock',
      icon: Icons.shield,
      permissionKey: 'deviceAdmin',
      request: (ch) => ch.requestDeviceAdminPermission(),
    ),
  ];

  bool get _allGranted =>
      _permissions.isNotEmpty && _permissions.values.every((v) => v == true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final perms = await _lockChannel.checkPermissions();
      if (!mounted) return;
      setState(() => _permissions = perms);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Vaultix'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final granted = _permissions[step.permissionKey] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(step.icon, size: 32),
                    title: Text(step.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(step.subtitle),
                    trailing: granted
                        ? const Icon(Icons.check_circle,
                            color: Colors.green, size: 28)
                        : OutlinedButton(
                            onPressed: () => step.request(_lockChannel),
                            child: const Text('Grant'),
                          ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _allGranted ? () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_completed', true);
                  if (!context.mounted) return;
                  context.go('/home');
                } : null,
                child: const Text('Continue to App'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
