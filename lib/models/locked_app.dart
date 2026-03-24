class LockedApp {
  final String packageName;
  final String appName;
  final bool isHardLock;
  final DateTime lockEndTime;

  const LockedApp({
    required this.packageName,
    required this.appName,
    required this.isHardLock,
    required this.lockEndTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isHardLock': isHardLock,
      'lockEndTime': lockEndTime.millisecondsSinceEpoch,
    };
  }

  factory LockedApp.fromMap(Map<String, dynamic> map) {
    return LockedApp(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      isHardLock: map['isHardLock'] as bool,
      lockEndTime: DateTime.fromMillisecondsSinceEpoch(map['lockEndTime'] as int),
    );
  }

  @override
  String toString() {
    return 'LockedApp(packageName: $packageName, appName: $appName, isHardLock: $isHardLock, lockEndTime: $lockEndTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LockedApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}
