import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/lock_status.dart';
import '../services/lock_channel.dart';
import '../widgets/active_lock_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _lockChannel = LockChannel();
  Map<String, bool> _permissions = {};
  LockStatus _lockStatus = const LockStatus(
    isActive: false,
    isHard: false,
    lockedApps: [],
    lockedAppNames: [],
    endTimeEpoch: 0,
  );
  int _currentTab = 0;

  bool get _anyPermissionMissing =>
      _permissions.isNotEmpty && _permissions.values.any((v) => v != true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    try {
      final perms = await _lockChannel.checkPermissions();
      final status = await _lockChannel.getLockStatus();
      if (!mounted) return;
      setState(() {
        _permissions = perms;
        _lockStatus = status;
      });
    } catch (_) {}
  }

  Future<void> _unlock() async {
    try {
      final pinRequired = await _lockChannel.hasPin();
      if (pinRequired) {
        if (!mounted) return;
        final verified = await _showPinDialog();
        if (!verified) return;
      }
      await _lockChannel.stopLock();
      await _loadData();
    } catch (_) {}
  }

  Future<bool> _unlockApp(String packageName) async {
    try {
      final pinRequired = await _lockChannel.hasPin();
      if (pinRequired) {
        if (!mounted) return false;
        final verified = await _showPinDialog();
        if (!verified) return false;
      }
      await _lockChannel.unlockApp(packageName);
      await _loadData();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _showPinDialog() async {
    final pinController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '4-digit PIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final pin = pinController.text;
              if (pin.length != 4) return;
              final ok = await _lockChannel.verifyPin(pin);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Incorrect PIN')));
                Navigator.of(ctx).pop(false);
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaultix'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_anyPermissionMissing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.deepPurple.shade900,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Setup required',
                        style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context.push('/onboarding');
                      _loadData();
                    },
                    child: const Text('Fix',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _lockStatus.isActive
                ? ActiveLockCard(
                    status: _lockStatus,
                    onUnlock: _lockStatus.isHard ? null : _unlock,
                    onUnlockApp: _lockStatus.isHard ? null : _unlockApp,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            size: 64, color: Color(0xFF636366)),
                        const SizedBox(height: 16),
                        const Text('No active locks',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('Tap + to lock an app',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await context.push('/new-lock');
                _loadData();
              },
              child: const Icon(Icons.lock),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) async {
          if (index == 1) {
            await context.push('/history');
            _loadData();
          } else if (index == 2) {
            await context.push('/settings');
            _loadData();
          } else {
            setState(() => _currentTab = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
