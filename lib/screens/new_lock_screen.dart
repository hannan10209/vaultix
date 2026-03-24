import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/installed_app_info.dart';
import '../services/lock_channel.dart';
import 'app_picker_screen.dart';

class NewLockScreen extends StatefulWidget {
  const NewLockScreen({super.key});

  @override
  State<NewLockScreen> createState() => _NewLockScreenState();
}

class _SelectedApp {
  final String packageName;
  final String appName;
  const _SelectedApp({required this.packageName, required this.appName});
}

class _NewLockScreenState extends State<NewLockScreen> {
  final _lockChannel = LockChannel();
  final List<_SelectedApp> _selectedApps = [];
  List<InstalledAppInfo>? _cachedApps;
  Set<String> _alreadyLockedPackages = {};

  // Duration wheels
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;
  int _hours = 0;
  int _minutes = 30;
  int _seconds = 0;

  // Lock type
  bool _isHardLock = false;

  // Presets in seconds
  final List<int> _presetSeconds = [1800, 3600, 7200, 14400, 28800];
  final List<String> _presetLabels = ['30m', '1h', '2h', '4h', '8h'];

  int get _totalSeconds => _hours * 3600 + _minutes * 60 + _seconds;
  bool get _canStart => _selectedApps.isNotEmpty && _totalSeconds > 0;

  String get _endTimeText {
    if (_totalSeconds == 0) return '';
    final end = DateTime.now().add(Duration(seconds: _totalSeconds));
    final h = end.hour.toString().padLeft(2, '0');
    final m = end.minute.toString().padLeft(2, '0');
    return 'Unlocks at $h:$m';
  }

  @override
  void initState() {
    super.initState();
    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
    _secondsController = FixedExtentScrollController(initialItem: _seconds ~/ 15);
    _loadLockedApps();
  }

  Future<void> _loadLockedApps() async {
    try {
      final status = await _lockChannel.getLockStatus();
      if (!mounted) return;
      setState(() {
        _alreadyLockedPackages = status.lockedApps.toSet();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _applyPreset(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    setState(() {
      _hours = h;
      _minutes = m;
      _seconds = 0;
    });
    _hoursController.animateToItem(h,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _minutesController.animateToItem(m,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _secondsController.animateToItem(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _pickApps() async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => AppPickerScreen(lockedPackages: _alreadyLockedPackages),
      ),
    );
    if (result == null || result.isEmpty) return;

    _cachedApps ??= await _lockChannel.getInstalledApps();
    final apps = _cachedApps!;
    final picked = <_SelectedApp>[];
    for (final pkg in result) {
      final match = apps.where((a) => a.packageName == pkg).firstOrNull;
      picked.add(_SelectedApp(
        packageName: pkg,
        appName: match?.appName ?? pkg,
      ));
    }

    setState(() {
      final existing = _selectedApps.map((a) => a.packageName).toSet();
      for (final app in picked) {
        if (!existing.contains(app.packageName)) {
          _selectedApps.add(app);
        }
      }
    });
  }

  Future<void> _startLock() async {
    final packages = _selectedApps.map((a) => a.packageName).toList();
    await _lockChannel.startLock(
      packages: packages,
      durationSeconds: _totalSeconds,
      isHard: _isHardLock,
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Lock'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // ── APPS ──
          _sectionLabel('APPS'),
          const SizedBox(height: 8),
          if (_selectedApps.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2C2C2E)),
              ),
              child: Center(
                child: Text('No apps selected',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ),
            )
          else
            ...List.generate(_selectedApps.length, (index) {
              final app = _selectedApps[index];
              return Container(
                margin: EdgeInsets.only(bottom: index < _selectedApps.length - 1 ? 6 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2C2C2E)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.apps, size: 20, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(app.appName,
                          style: const TextStyle(fontSize: 15, color: Colors.white)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedApps.removeAt(index)),
                      child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickApps,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: Color(0xFF7C3AED)),
                  SizedBox(width: 6),
                  Text('Add apps',
                      style: TextStyle(color: Color(0xFF7C3AED), fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── DURATION ──
          _sectionLabel('DURATION'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2C2C2E)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _wheelGroup(
                        controller: _hoursController,
                        itemCount: 24,
                        label: 'h',
                        labelBuilder: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _hours = i),
                      ),
                      const SizedBox(width: 20),
                      _wheelGroup(
                        controller: _minutesController,
                        itemCount: 60,
                        label: 'm',
                        labelBuilder: (i) => i.toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _minutes = i),
                      ),
                      const SizedBox(width: 20),
                      _wheelGroup(
                        controller: _secondsController,
                        itemCount: 4,
                        label: 's',
                        labelBuilder: (i) => (i * 15).toString().padLeft(2, '0'),
                        onChanged: (i) => setState(() => _seconds = i * 15),
                      ),
                    ],
                  ),
                ),
                if (_totalSeconds > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_endTimeText,
                        style: const TextStyle(color: Color(0xFF9F67FF), fontSize: 13)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_presetLabels.length, (index) {
              final isActive = _presetSeconds[index] == _totalSeconds;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _applyPreset(_presetSeconds[index]),
                  child: Container(
                    margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF2C2C2E),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _presetLabels[index],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // ── LOCK MODE ──
          _sectionLabel('LOCK MODE'),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _lockModeCard(
                    icon: Icons.lock_open_rounded,
                    title: 'Soft Lock',
                    subtitle: 'Unlock anytime',
                    selected: !_isHardLock,
                    onTap: () => setState(() => _isHardLock = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _lockModeCard(
                    icon: Icons.lock_rounded,
                    title: 'Hard Lock',
                    subtitle: 'Locked until timer ends',
                    selected: _isHardLock,
                    onTap: () => setState(() => _isHardLock = true),
                  ),
                ),
              ],
            ),
          ),
          if (_isHardLock) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1A00),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9500)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hard lock cannot be reversed. Restart your phone to break it early.',
                      style: TextStyle(color: Color(0xFFFF9500), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _canStart ? _startLock : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Start Lock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ));
  }

  Widget _wheelGroup({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String label,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 44,
            diameterRatio: 1.4,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                final isSelected = controller.hasClients &&
                    controller.selectedItem == index;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    child: Text(labelBuilder(index)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Widget _lockModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = selected ? const Color(0xFF7C3AED) : const Color(0xFF636366);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFF2C2C2E),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: accent),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, color: selected ? Colors.white : Colors.grey.shade300)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
