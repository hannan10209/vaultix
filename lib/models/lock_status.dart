class LockStatus {
  final bool isActive;
  final bool isHard;
  final List<String> lockedApps;
  final List<String> lockedAppNames;
  final int endTimeEpoch;
  final Map<String, int> appEndTimes;

  const LockStatus({
    required this.isActive,
    required this.isHard,
    required this.lockedApps,
    required this.lockedAppNames,
    required this.endTimeEpoch,
    this.appEndTimes = const {},
  });

  factory LockStatus.fromMap(Map<String, dynamic> map) {
    final rawAppEndTimes = map['appEndTimes'];
    final appEndTimes = <String, int>{};
    if (rawAppEndTimes is Map) {
      for (final entry in rawAppEndTimes.entries) {
        appEndTimes[entry.key.toString()] = (entry.value as num).toInt();
      }
    }
    return LockStatus(
      isActive: map['isActive'] as bool? ?? false,
      isHard: map['isHard'] as bool? ?? false,
      lockedApps: List<String>.from(map['lockedApps'] ?? []),
      lockedAppNames: List<String>.from(map['lockedAppNames'] ?? []),
      endTimeEpoch: (map['endTimeEpoch'] as num?)?.toInt() ?? 0,
      appEndTimes: appEndTimes,
    );
  }

  int endTimeForApp(String packageName) {
    return appEndTimes[packageName] ?? endTimeEpoch;
  }

  DateTime get endTime =>
      DateTime.fromMillisecondsSinceEpoch(endTimeEpoch);

  String get endTimeFormatted {
    final dt = endTime;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
