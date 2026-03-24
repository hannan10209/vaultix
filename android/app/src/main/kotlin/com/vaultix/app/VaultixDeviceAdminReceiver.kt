package com.vaultix.app

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class VaultixDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
    }
}
