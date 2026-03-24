import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/lock_status.dart';
import '../models/installed_app_info.dart';
import '../services/lock_channel.dart';

class ActiveLockCard extends StatefulWidget {
  final LockStatus status;
  final VoidCallback? onUnlock;

  const ActiveLockCard({
    super.key,
    required this.status,
    this.onUnlock,
  });

  @override
  State<ActiveLockCard> createState() => _ActiveLockCardState();
}

class _ActiveLockCardState extends State<ActiveLockCard> {
  Timer? _timer;
  List<InstalledAppInfo> _appInfos = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadAppIcons();
  }

  @override
  void didUpdateWidget(covariant ActiveLockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status.lockedApps.length != widget.status.lockedApps.length ||
        oldWidget.status.endTimeEpoch != widget.status.endTimeEpoch) {
      _loadAppIcons();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppIcons() async {
    try {
      final apps = await LockChannel().getInstalledApps();
      if (!mounted) return;
      final locked = widget.status.lockedApps.toSet();
      setState(() {
        _appInfos = apps.where((a) => locked.contains(a.packageName)).toList();
      });
    } catch (_) {}
  }

  String _formatCountdown(int endEpoch) {
    final end = DateTime.fromMillisecondsSinceEpoch(endEpoch);
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return '0m 00s';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  Widget _buildAppIcon(String packageName) {
    final match = _appInfos.where((a) => a.packageName == packageName).firstOrNull;
    if (match != null) {
      try {
        final bytes = base64Decode(match.iconBase64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: 48, height: 48, fit: BoxFit.contain),
        );
      } catch (_) {}
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.android, color: Colors.white54, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appCount = widget.status.lockedApps.length;
    final accentColor = widget.status.isHard ? Colors.red : const Color(0xFF7C3AED);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Text(
                '$appCount app${appCount == 1 ? '' : 's'} locked',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              if (widget.status.isHard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Hard Lock',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else if (widget.onUnlock != null)
                TextButton.icon(
                  onPressed: widget.onUnlock,
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Unlock All'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.status.lockedApps.length,
            itemBuilder: (context, index) {
              final pkg = widget.status.lockedApps[index];
              final name = index < widget.status.lockedAppNames.length
                  ? widget.status.lockedAppNames[index]
                  : pkg;
              final appEnd = widget.status.endTimeForApp(pkg);
              final countdown = _formatCountdown(appEnd);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    _buildAppIcon(pkg),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                countdown,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'Locked',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
