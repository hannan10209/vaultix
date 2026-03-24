import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/installed_app_info.dart';
import '../services/lock_channel.dart';

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

  // Duration
  int? _selectedPresetIndex;
  final List<int> _presetMinutes = [30, 60, 120, 240, 480];
  final List<String> _presetLabels = [
    '30 min',
    '1 hr',
    '2 hr',
    '4 hr',
    '8 hr',
    'Custom'
  ];
  int _customHours = 0;
  int _customMinutes = 30;
  bool _isCustom = false;

  // Lock type
  bool _isHardLock = false;

  int get _durationMinutes {
    if (_isCustom) return _customHours * 60 + _customMinutes;
    if (_selectedPresetIndex != null &&
        _selectedPresetIndex! < _presetMinutes.length) {
      return _presetMinutes[_selectedPresetIndex!];
    }
    return 0;
  }

  bool get _canStart => _selectedApps.isNotEmpty && _durationMinutes > 0;

  String get _endTimeText {
    if (_durationMinutes == 0) return '';
    final end = DateTime.now().add(Duration(minutes: _durationMinutes));
    final h = end.hour.toString().padLeft(2, '0');
    final m = end.minute.toString().padLeft(2, '0');
    return 'Lock ends at $h:$m';
  }

  Future<void> _pickApps() async {
    final result = await context.push<Set<String>>('/app-picker');
    if (result == null || result.isEmpty) return;

    _cachedApps ??= await _lockChannel.getInstalledApps();
    final apps = _cachedApps!;
    final newApps = <_SelectedApp>[];
    for (final pkg in result) {
      final match = apps.where((a) => a.packageName == pkg).firstOrNull;
      newApps.add(_SelectedApp(
        packageName: pkg,
        appName: match?.appName ?? pkg,
      ));
    }

    setState(() {
      final existing = _selectedApps.map((a) => a.packageName).toSet();
      for (final app in newApps) {
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
      durationMinutes: _durationMinutes,
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
        padding: const EdgeInsets.all(16),
        children: [
          // ── SECTION 1: Select Apps ──
          _sectionHeader('Select Apps'),
          const SizedBox(height: 8),
          if (_selectedApps.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('No apps selected yet',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedApps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final app = _selectedApps[index];
                  return Chip(
                    label: Text(app.appName),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _selectedApps.removeAt(index));
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickApps,
            icon: const Icon(Icons.add),
            label: const Text('Add apps'),
          ),

          const SizedBox(height: 24),

          // ── SECTION 2: Lock Duration ──
          _sectionHeader('Lock Duration'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_presetLabels.length, (index) {
              final isPresetSelected =
                  !_isCustom && _selectedPresetIndex == index;
              final isCustomSelected = _isCustom && index == 5;
              final selected = isPresetSelected || isCustomSelected;
              return ChoiceChip(
                label: Text(_presetLabels[index]),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (index == 5) {
                      _isCustom = true;
                      _selectedPresetIndex = null;
                    } else {
                      _isCustom = false;
                      _selectedPresetIndex = index;
                    }
                  });
                },
              );
            }),
          ),
          if (_isCustom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _customHours,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                    ),
                    items: List.generate(24, (i) {
                      return DropdownMenuItem(value: i, child: Text('$i'));
                    }),
                    onChanged: (v) => setState(() => _customHours = v ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _customMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                    ),
                    items: List.generate(12, (i) {
                      final v = i * 5;
                      return DropdownMenuItem(value: v, child: Text('$v'));
                    }),
                    onChanged: (v) =>
                        setState(() => _customMinutes = v ?? 0),
                  ),
                ),
              ],
            ),
          ],
          if (_durationMinutes > 0) ...[
            const SizedBox(height: 8),
            Text(_endTimeText,
                style: const TextStyle(
                    color: Color(0xFF636366), fontSize: 14)),
          ],

          const SizedBox(height: 24),

          // ── SECTION 3: Lock Type ──
          _sectionHeader('Lock Type'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _lockTypeCard(
                  icon: Icons.lock_open,
                  title: 'Soft Lock',
                  subtitle: 'Can be unlocked from settings',
                  selected: !_isHardLock,
                  onTap: () => setState(() => _isHardLock = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lockTypeCard(
                  icon: Icons.lock,
                  title: 'Hard Lock',
                  subtitle:
                      'Cannot be unlocked until time expires or device restarts',
                  selected: _isHardLock,
                  onTap: () => setState(() => _isHardLock = true),
                ),
              ),
            ],
          ),
          if (_isHardLock) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1A00),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9500)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF9500)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hard lock cannot be reversed. Your phone must be restarted to break this lock early.',
                      style:
                          TextStyle(color: Color(0xFFFF9500), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _canStart ? _startLock : null,
              child: const Text('Start Lock'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _lockTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF7C3AED)
                : const Color(0xFF2C2C2E),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: selected
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF636366)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF636366))),
          ],
        ),
      ),
    );
  }
}
