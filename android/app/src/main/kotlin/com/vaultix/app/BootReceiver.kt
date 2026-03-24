package com.vaultix.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            if (!LockStateManager.isLockActive(context)) return

            val endEpoch = LockStateManager.getLockEndTime(context)
            if (endEpoch <= System.currentTimeMillis()) {
                // Lock has expired — record completed history entry
                LockStateManager.updateLastHistoryEndTime(
                    context, endEpoch, wasInterrupted = false
                )
                LockStateManager.setLockActive(context, false)
                LockStateManager.clearAll(context)
                return
            }

            val appNames = LockStateManager.getLockedAppNames(context)
            VaultixForegroundService.start(context, appNames, endEpoch)
        }
    }
}
