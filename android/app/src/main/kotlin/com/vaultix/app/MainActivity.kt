package com.vaultix.app

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Base64
import android.view.accessibility.AccessibilityManager
import android.app.AppOpsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import androidx.lifecycle.lifecycleScope
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.vaultix.app/lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLock" -> {
                    try {
                        val newPackages = call.argument<List<String>>("packages") ?: emptyList()
                        val durationSeconds = call.argument<Int>("durationSeconds") ?: 0
                        val isHard = call.argument<Boolean>("isHard") ?: false

                        val pm = packageManager
                        val newAppNames = newPackages.map { pkg ->
                            try {
                                val ai = pm.getApplicationInfo(pkg, 0)
                                pm.getApplicationLabel(ai).toString()
                            } catch (_: Exception) {
                                pkg
                            }
                        }

                        // Merge with existing locked apps if a lock is already active
                        val existingPackages = if (LockStateManager.isLockActive(this))
                            LockStateManager.getLockedApps(this) else emptyList()
                        val existingNames = if (LockStateManager.isLockActive(this))
                            LockStateManager.getLockedAppNames(this) else emptyList()

                        val mergedPackages = existingPackages.toMutableList()
                        val mergedNames = existingNames.toMutableList()
                        for (i in newPackages.indices) {
                            if (!mergedPackages.contains(newPackages[i])) {
                                mergedPackages.add(newPackages[i])
                                mergedNames.add(newAppNames[i])
                            }
                        }

                        val startTime = System.currentTimeMillis()
                        val newEndTime = startTime + (durationSeconds * 1000L)

                        // Per-app end times: keep existing, add new
                        val appEndTimes = LockStateManager.getAppEndTimes(this).toMutableMap()
                        for (pkg in newPackages) {
                            appEndTimes[pkg] = newEndTime
                        }

                        // Global end time = latest of all per-app end times
                        val endTime = appEndTimes.values.maxOrNull() ?: newEndTime

                        LockStateManager.setLockedApps(this, mergedPackages)
                        LockStateManager.setLockedAppNames(this, mergedNames)
                        LockStateManager.setLockActive(this, true)
                        LockStateManager.setHardLock(this, isHard)
                        if (LockStateManager.getLockStartTime(this) == 0L) {
                            LockStateManager.saveLockStartTime(this, startTime)
                        }
                        LockStateManager.saveLockEndTime(this, endTime)
                        LockStateManager.setAppEndTimes(this, appEndTimes)

                        LockStateManager.appendLockHistory(this, LockHistoryEntry(
                            packageNames = newPackages,
                            appNames = newAppNames,
                            startEpoch = startTime,
                            endEpoch = 0L,
                            wasHard = isHard,
                            wasInterrupted = false
                        ))

                        VaultixForegroundService.start(this, mergedNames, endTime)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_LOCK_ERROR", e.message, null)
                    }
                }

                "stopLock" -> {
                    if (LockStateManager.isHardLock(this)) {
                        result.error("HARD_LOCK", "Cannot stop a hard lock before it expires", null)
                    } else {
                        val hadOpenEntries = LockStateManager.completeAllOpenHistoryEntries(this)
                        if (!hadOpenEntries) {
                            val packages = LockStateManager.getLockedApps(this)
                            val appNames = LockStateManager.getLockedAppNames(this)
                            val startTime = LockStateManager.getLockStartTime(this)
                            if (packages.isNotEmpty() && startTime > 0) {
                                LockStateManager.appendLockHistory(this, LockHistoryEntry(
                                    packageNames = packages,
                                    appNames = appNames,
                                    startEpoch = startTime,
                                    endEpoch = System.currentTimeMillis(),
                                    wasHard = false,
                                    wasInterrupted = false
                                ))
                            }
                        }
                        LockStateManager.setLockActive(this, false)
                        LockStateManager.clearAll(this)
                        VaultixForegroundService.stop(this)
                        result.success(true)
                    }
                }

                "unlockApp" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    if (LockStateManager.isHardLock(this)) {
                        result.error("HARD_LOCK", "Cannot unlock a hard-locked app", null)
                    } else if (pkg.isEmpty()) {
                        result.error("INVALID", "No package name provided", null)
                    } else {
                        val packages = LockStateManager.getLockedApps(this).toMutableList()
                        val names = LockStateManager.getLockedAppNames(this).toMutableList()
                        val appEndTimes = LockStateManager.getAppEndTimes(this).toMutableMap()

                        val idx = packages.indexOf(pkg)
                        val appName = if (idx >= 0 && idx < names.size) names[idx] else pkg

                        // Record history for this single app
                        val startTime = LockStateManager.getLockStartTime(this)
                        if (startTime > 0) {
                            LockStateManager.appendLockHistory(this, LockHistoryEntry(
                                packageNames = listOf(pkg),
                                appNames = listOf(appName),
                                startEpoch = startTime,
                                endEpoch = System.currentTimeMillis(),
                                wasHard = false,
                                wasInterrupted = false
                            ))
                        }

                        // Remove from locked lists
                        if (idx >= 0) {
                            packages.removeAt(idx)
                            if (idx < names.size) names.removeAt(idx)
                        }
                        appEndTimes.remove(pkg)

                        if (packages.isEmpty()) {
                            // No more locked apps — clear everything
                            LockStateManager.setLockActive(this, false)
                            LockStateManager.clearAll(this)
                            VaultixForegroundService.stop(this)
                        } else {
                            LockStateManager.setLockedApps(this, packages)
                            LockStateManager.setLockedAppNames(this, names)
                            LockStateManager.setAppEndTimes(this, appEndTimes)
                            val newEnd = appEndTimes.values.maxOrNull() ?: 0L
                            LockStateManager.saveLockEndTime(this, newEnd)
                            VaultixForegroundService.start(this, names, newEnd)
                        }
                        result.success(true)
                    }
                }

                "getLockStatus" -> {
                    val appEndTimes = LockStateManager.getAppEndTimes(this)
                    val status = mapOf(
                        "isActive" to LockStateManager.isLockActive(this),
                        "isHard" to LockStateManager.isHardLock(this),
                        "lockedApps" to LockStateManager.getLockedApps(this),
                        "lockedAppNames" to LockStateManager.getLockedAppNames(this),
                        "endTimeEpoch" to LockStateManager.getLockEndTime(this),
                        "appEndTimes" to appEndTimes
                    )
                    result.success(status)
                }

                "checkPermissions" -> {
                    val permissions = mapOf(
                        "usageStats" to hasUsageStatsPermission(),
                        "accessibility" to isAccessibilityServiceEnabled(),
                        "overlay" to hasOverlayPermission(),
                        "deviceAdmin" to isDeviceAdminEnabled()
                    )
                    result.success(permissions)
                }

                "requestUsageStatsPermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "requestAccessibilityPermission" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }

                "requestDeviceAdminPermission" -> {
                    val componentName = ComponentName(this, VaultixDeviceAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                        putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "Required to prevent uninstallation during a hard lock session"
                        )
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "getInstalledApps" -> {
                    lifecycleScope.launch {
                        try {
                            val apps = withContext(Dispatchers.IO) {
                                getInstalledAppsList()
                            }
                            result.success(apps)
                        } catch (e: Exception) {
                            result.error("GET_APPS_ERROR", e.message, null)
                        }
                    }
                }

                "setPin" -> {
                    val pin = call.argument<String>("pin") ?: ""
                    LockStateManager.savePin(this, pin)
                    result.success(true)
                }

                "verifyPin" -> {
                    val pin = call.argument<String>("pin") ?: ""
                    result.success(LockStateManager.verifyPin(this, pin))
                }

                "hasPin" -> {
                    result.success(LockStateManager.hasPin(this))
                }

                "clearPin" -> {
                    LockStateManager.clearPin(this)
                    result.success(true)
                }

                "clearHistory" -> {
                    LockStateManager.clearHistory(this)
                    result.success(true)
                }

                "getHistory" -> {
                    val history = LockStateManager.getLockHistory(this)
                    val list = history.map { entry ->
                        mapOf(
                            "appNames" to entry.appNames,
                            "startEpoch" to entry.startEpoch,
                            "endEpoch" to entry.endEpoch,
                            "wasHard" to entry.wasHard,
                            "wasInterrupted" to entry.wasInterrupted
                        )
                    }
                    result.success(list)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        for (service in enabledServices) {
            val serviceId = service.resolveInfo.serviceInfo
            if (serviceId.packageName == packageName &&
                serviceId.name == VaultixAccessibilityService::class.java.name
            ) {
                return true
            }
        }
        return false
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun isDeviceAdminEnabled(): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, VaultixDeviceAdminReceiver::class.java)
        return dpm.isAdminActive(componentName)
    }

    private fun getInstalledAppsList(): List<Map<String, String>> {
        val pm = packageManager
        // Query all apps that have a launcher activity — these are the apps the user can open
        val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(launcherIntent, 0)
        val result = mutableListOf<Map<String, String>>()
        val seen = mutableSetOf<String>()

        for (ri in resolveInfos) {
            val pkg = ri.activityInfo.packageName
            // Skip ourselves and duplicates
            if (pkg == packageName) continue
            if (!seen.add(pkg)) continue

            val appName = ri.loadLabel(pm).toString()
            val iconDrawable = ri.loadIcon(pm)
            val iconBase64 = drawableToBase64(iconDrawable)

            result.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "icon" to iconBase64
                )
            )
        }

        return result
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 48
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 48
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 50, stream)
        val byteArray = stream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }
}
