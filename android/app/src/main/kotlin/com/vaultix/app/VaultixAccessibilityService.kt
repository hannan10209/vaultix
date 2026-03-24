package com.vaultix.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class VaultixAccessibilityService : AccessibilityService() {

    private val ignoredPackages = setOf(
        "com.vaultix.app",
        "com.android.systemui",
        "com.android.launcher",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        "com.sec.android.app.launcher",
        "com.samsung.android.app.routines",
        "com.android.settings"
    )

    private var lastBlockedTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 200
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (ignoredPackages.contains(packageName)) return

        val isActive = LockStateManager.isLockActive(this)
        if (!isActive) return

        val endTime = LockStateManager.getLockEndTime(this)
        if (endTime > 0 && System.currentTimeMillis() >= endTime) {
            LockStateManager.completeAllOpenHistoryEntries(this)
            LockStateManager.setLockActive(this, false)
            LockStateManager.clearAll(this)
            return
        }

        // Debounce to avoid rapid re-triggers
        val now = System.currentTimeMillis()
        if (now - lastBlockedTime < 500) return

        val lockedApps = LockStateManager.getLockedApps(this)
        if (lockedApps.contains(packageName)) {
            lastBlockedTime = now
            val isHard = LockStateManager.isHardLock(this)
            val intent = Intent(this, BlockOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("blocked_package", packageName)
                putExtra("is_hard_lock", isHard)
            }
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Required override
    }
}
