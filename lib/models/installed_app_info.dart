class InstalledAppInfo {
  final String packageName;
  final String appName;
  final String iconBase64;

  const InstalledAppInfo({
    required this.packageName,
    required this.appName,
    required this.iconBase64,
  });

  factory InstalledAppInfo.fromMap(Map<String, dynamic> map) {
    return InstalledAppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      iconBase64: map['icon'] as String,
    );
  }
}
