import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/lock_status.dart';
import '../services/lock_channel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _lockChannel = LockChannel();
  bool _hasPinSet = false;
  LockStatus _lockStatus = const LockStatus(
    isActive: false,
    isHard: false,
    lockedApps: [],
    lockedAppNames: [],
    endTimeEpoch: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final hasPin = await _lockChannel.hasPin();
      final status = await _lockChannel.getLockStatus();
      if (!mounted) return;
      setState(() {
        _hasPinSet = hasPin;
        _lockStatus = status;
      });
    } catch (_) {}
  }

  Future<void> _showSetPinDialog() async {
    final pin1Controller = TextEditingController();
    final pin2Controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pin1Controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pin2Controller,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final pin1 = pin1Controller.text;
    final pin2 = pin2Controller.text;

    if (pin1.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      }
      return;
    }

    if (pin1 != pin2) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PINs do not match')));
      }
      return;
    }

    await _lockChannel.setPin(pin1);
    if (!mounted) return;
    setState(() => _hasPinSet = true);
  }

  Future<void> _clearPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN protection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _lockChannel.clearPin();
    if (!mounted) return;
    setState(() => _hasPinSet = false);
  }

  Future<void> _forceStopLocks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force stop all locks?'),
        content: const Text('This will unlock all currently soft-locked apps.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Force Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _lockChannel.stopLock();
    } catch (_) {}
    await _loadState();
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all lock history?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _lockChannel.clearHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lock history cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canForceStop =
        _lockStatus.isActive && !_lockStatus.isHard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Soft Lock Protection ──
          _sectionHeader('Soft Lock Protection'),
          SwitchListTile(
            title: const Text('Require PIN to unlock soft locks'),
            value: _hasPinSet,
            onChanged: (val) {
              if (val) {
                _showSetPinDialog();
              } else {
                _clearPin();
              }
            },
          ),
          if (_hasPinSet)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _showSetPinDialog,
                  child: const Text('Change PIN'),
                ),
              ),
            ),

          const Divider(),

          // ── About ──
          _sectionHeader('About'),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('App name'),
            trailing: Text('Vaultix'),
          ),
          ListTile(
            title: const Text('Permissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/onboarding'),
          ),

          const Divider(),

          // ── Danger Zone ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Danger Zone',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400)),
          ),
          ListTile(
            title: Text('Force stop all locks',
                style: TextStyle(
                    color: canForceStop ? Colors.red.shade300 : Colors.grey)),
            enabled: canForceStop,
            onTap: canForceStop ? _forceStopLocks : null,
          ),
          ListTile(
            title: Text('Clear all lock history',
                style: TextStyle(color: Colors.red.shade300)),
            onTap: _clearHistory,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}
