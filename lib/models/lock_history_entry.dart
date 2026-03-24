class LockHistoryEntry {
  final List<String> appNames;
  final int startEpoch;
  final int endEpoch;
  final bool wasHard;
  final bool wasInterrupted;

  const LockHistoryEntry({
    required this.appNames,
    required this.startEpoch,
    required this.endEpoch,
    required this.wasHard,
    required this.wasInterrupted,
  });

  factory LockHistoryEntry.fromMap(Map<String, dynamic> map) {
    return LockHistoryEntry(
      appNames: List<String>.from(map['appNames'] ?? []),
      startEpoch: (map['startEpoch'] as num?)?.toInt() ?? 0,
      endEpoch: (map['endEpoch'] as num?)?.toInt() ?? 0,
      wasHard: map['wasHard'] as bool? ?? false,
      wasInterrupted: map['wasInterrupted'] as bool? ?? false,
    );
  }

  String get formattedDuration {
    if (endEpoch <= 0 || startEpoch <= 0) return 'In progress';
    final diff = endEpoch - startEpoch;
    final totalMinutes = diff ~/ 60000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  DateTime get startTime =>
      DateTime.fromMillisecondsSinceEpoch(startEpoch);

  DateTime get endTime =>
      DateTime.fromMillisecondsSinceEpoch(endEpoch);
}
