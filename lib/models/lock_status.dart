class LockStatus {
  final bool isActive;
  final bool isHard;
  final List<String> lockedApps;
  final List<String> lockedAppNames;
  final int endTimeEpoch;

  const LockStatus({
    required this.isActive,
    required this.isHard,
    required this.lockedApps,
    required this.lockedAppNames,
    required this.endTimeEpoch,
  });

  factory LockStatus.fromMap(Map<String, dynamic> map) {
    return LockStatus(
      isActive: map['isActive'] as bool? ?? false,
      isHard: map['isHard'] as bool? ?? false,
      lockedApps: List<String>.from(map['lockedApps'] ?? []),
      lockedAppNames: List<String>.from(map['lockedAppNames'] ?? []),
      endTimeEpoch: (map['endTimeEpoch'] as num?)?.toInt() ?? 0,
    );
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
