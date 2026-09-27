package com.chargealarm.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground service that keeps ChargeAlarm's monitoring alive while the
 * app is backgrounded or the screen is locked, per the specification's
 * Android background requirement. It is intentionally self-sufficient: it
 * decides on its own (reading persisted settings directly, see
 * [BatteryReadingUtils]) whether the target has been reached and triggers
 * [AlarmPlugin] directly, so charging alerts keep working even if the
 * Flutter engine/Activity has been fully torn down by the OS. When a
 * Flutter UI *is* attached, [BatteryMonitorPlugin.activeSink] additionally
 * receives the same readings for live dashboard updates.
 *
 * This satisfies "works when the screen is locked and the app is not
 * visible" to the extent Android's foreground-service and OEM
 * battery-management rules allow; very aggressive OEM background killers
 * (documented per-vendor, e.g. some MIUI/ColorOS configurations) can still
 * suspend it, which is a platform limitation outside any app's control —
 * see README.md's platform limitations section.
 */
class ChargeMonitorService : Service() {

    private var receiver: BroadcastReceiver? = null
    private var targetAlreadyNotified = false
    private var lastWasCharging = false

    companion object {
        private const val STATUS_CHANNEL_ID = "charge_monitor_status_channel"
        private const val STATUS_NOTIFICATION_ID = 2001

        fun start(context: Context) {
            val intent = Intent(context, ChargeMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ChargeMonitorService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(STATUS_NOTIFICATION_ID, buildStatusNotification())
        registerBatteryReceiver()
        // Evaluate the state we're in right now, in case the service was
        // just (re)started while already above target (edge case: "device
        // reboot" / "app process killed" while charging).
        onReading(BatteryReadingUtils.currentSticky(this))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == AlarmPlugin.ACTION_STOP_ALARM) {
            AlarmPlugin.stopAlarm(this)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        receiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                // Already unregistered.
            }
        }
        super.onDestroy()
    }

    private fun registerBatteryReceiver() {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                onReading(BatteryReadingUtils.fromIntent(intent))
            }
        }
        registerReceiver(receiver, filter)
    }

    private fun onReading(reading: BatteryReadingUtils.Reading) {
        // Mirror to any live Flutter engine for the dashboard UI.
        BatteryMonitorPlugin.activeSink?.success(
            mapOf(
                "percentage" to reading.percentage,
                "connectionState" to reading.connectionState,
                "timestampMs" to reading.timestampMs,
            ),
        )

        val isCharging = reading.connectionState != BatteryReadingUtils.STATE_DISCONNECTED

        if (lastWasCharging && !isCharging) {
            // Just unplugged.
            targetAlreadyNotified = false
            if (BatteryReadingUtils.autoStopOnUnplug(this)) {
                AlarmPlugin.stopAlarm(this)
            }
            stopSelf()
            lastWasCharging = isCharging
            return
        }

        if (!lastWasCharging && isCharging) {
            targetAlreadyNotified = false
        }
        lastWasCharging = isCharging

        if (!isCharging || !BatteryReadingUtils.isAlarmEnabled(this)) return

        val target = BatteryReadingUtils.targetPercentage(this)
        if (reading.percentage >= target && !targetAlreadyNotified) {
            targetAlreadyNotified = true
            AlarmPlugin.startAlarm(
                this,
                BatteryReadingUtils.soundId(this),
                BatteryReadingUtils.vibrationEnabled(this),
                reading.percentage,
            )
        }
    }

    private fun buildStatusNotification(): android.app.Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(STATUS_CHANNEL_ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        STATUS_CHANNEL_ID,
                        "Charge monitoring",
                        NotificationManager.IMPORTANCE_MIN,
                    ).apply { description = "Shows that ChargeAlarm is watching your battery." },
                )
            }
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, STATUS_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_charging)
            .setContentTitle("ChargeAlarm is watching your battery")
            .setContentText("You'll be alerted at your target charge level.")
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .build()
    }
}
