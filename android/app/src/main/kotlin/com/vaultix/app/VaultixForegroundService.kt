package com.vaultix.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class VaultixForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "vaultix_lock_channel"
        private const val NOTIFICATION_ID = 1001
        private const val EXTRA_APP_NAMES = "locked_app_names"
        private const val EXTRA_END_EPOCH = "lock_end_epoch"

        fun start(context: Context, lockedAppNames: List<String>, endEpoch: Long) {
            val intent = Intent(context, VaultixForegroundService::class.java).apply {
                putStringArrayListExtra(EXTRA_APP_NAMES, ArrayList(lockedAppNames))
                putExtra(EXTRA_END_EPOCH, endEpoch)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, VaultixForegroundService::class.java)
            context.stopService(intent)
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lockedAppNames: List<String> = emptyList()
    private var lockEndEpoch: Long = 0L
    private lateinit var notificationManager: NotificationManager

    private val updateRunnable = object : Runnable {
        override fun run() {
            if (System.currentTimeMillis() >= lockEndEpoch) {
                // Lock expired
                LockStateManager.setLockActive(this@VaultixForegroundService, false)
                LockStateManager.clearAll(this@VaultixForegroundService)
                stopSelf()
                return
            }
            notificationManager.notify(NOTIFICATION_ID, buildNotification())
            handler.postDelayed(this, 60_000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(NotificationManager::class.java)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        lockedAppNames = intent?.getStringArrayListExtra(EXTRA_APP_NAMES) ?: emptyList()
        lockEndEpoch = intent?.getLongExtra(EXTRA_END_EPOCH, 0L) ?: 0L

        startForeground(NOTIFICATION_ID, buildNotification())

        // Start periodic updates
        handler.removeCallbacks(updateRunnable)
        handler.postDelayed(updateRunnable, 60_000)

        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(updateRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Vaultix Lock Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps Vaultix running to protect your focus"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        val endTimeStr = timeFormat.format(Date(lockEndEpoch))
        val appsText = if (lockedAppNames.isNotEmpty()) {
            lockedAppNames.joinToString(", ")
        } else {
            "Apps"
        }
        val contentText = "$appsText locked until $endTimeStr"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Vaultix \u2014 Focus Active")
                .setContentText(contentText)
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Vaultix \u2014 Focus Active")
                .setContentText(contentText)
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .build()
        }
    }
}
