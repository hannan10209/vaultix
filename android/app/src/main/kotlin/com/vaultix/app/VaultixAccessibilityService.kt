package com.vaultix.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class VaultixAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Don't block ourselves
        if (packageName == "com.vaultix.app") return

        val isActive = LockStateManager.isLockActive(this)
        if (!isActive) return

        val lockedApps = LockStateManager.getLockedApps(this)
        if (lockedApps.contains(packageName)) {
            val isHard = LockStateManager.isHardLock(this)
            val intent = Intent(this, BlockOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY)
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
