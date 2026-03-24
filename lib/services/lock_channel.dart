import 'package:flutter/services.dart';
import '../models/installed_app_info.dart';
import '../models/lock_history_entry.dart';
import '../models/lock_status.dart';

class LockChannel {
  static const _channel = MethodChannel('com.vaultix.app/lock');

  Future<bool> startLock({
    required List<String> packages,
    required int durationMinutes,
    required bool isHard,
  }) async {
    final result = await _channel.invokeMethod('startLock', {
      'packages': packages,
      'durationMinutes': durationMinutes,
      'isHard': isHard,
    });
    return result == true;
  }

  Future<bool> stopLock() async {
    final result = await _channel.invokeMethod('stopLock');
    return result == true;
  }

  Future<LockStatus> getLockStatus() async {
    final result = await _channel.invokeMethod('getLockStatus');
    return LockStatus.fromMap(Map<String, dynamic>.from(result));
  }

  Future<Map<String, bool>> checkPermissions() async {
    final result = await _channel.invokeMethod('checkPermissions');
    return Map<String, bool>.from(result);
  }

  Future<void> requestUsageStatsPermission() async {
    await _channel.invokeMethod('requestUsageStatsPermission');
  }

  Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  Future<void> requestAccessibilityPermission() async {
    await _channel.invokeMethod('requestAccessibilityPermission');
  }

  Future<void> requestDeviceAdminPermission() async {
    await _channel.invokeMethod('requestDeviceAdminPermission');
  }

  Future<List<InstalledAppInfo>> getInstalledApps() async {
    final result = await _channel.invokeMethod('getInstalledApps');
    final list = List<Map<dynamic, dynamic>>.from(result);
    return list
        .map((m) => InstalledAppInfo.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> setPin(String pin) async {
    await _channel.invokeMethod('setPin', {'pin': pin});
  }

  Future<bool> verifyPin(String pin) async {
    final result = await _channel.invokeMethod('verifyPin', {'pin': pin});
    return result == true;
  }

  Future<bool> hasPin() async {
    final result = await _channel.invokeMethod('hasPin');
    return result == true;
  }

  Future<void> clearPin() async {
    await _channel.invokeMethod('clearPin');
  }

  Future<void> clearHistory() async {
    await _channel.invokeMethod('clearHistory');
  }

  Future<List<LockHistoryEntry>> getHistory() async {
    final result = await _channel.invokeMethod('getHistory');
    final list = List<Map<dynamic, dynamic>>.from(result);
    return list
        .map((m) => LockHistoryEntry.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }
}
