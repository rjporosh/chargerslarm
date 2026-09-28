package com.chargealarm.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground service that keeps ChargeAlarm's monitoring alive while the
 * app is backgrounded, the screen is locked, or the app process has been
 * fully torn down by the OS. It is intentionally self-sufficient: it decides
 * on its own (reading persisted settings directly, see
 * [BatteryReadingUtils]) whether the target has been reached and triggers
 * [AlarmPlugin] directly, so charging alerts keep working even if no Flutter
 * engine is alive. When a Flutter UI *is* attached,
 * [BatteryMonitorPlugin.activeSink] additionally receives the same readings
 * for live dashboard updates.
 *
 * The service deliberately runs for the whole charge/unplug/re-plug cycle
 * rather than stopping itself on disconnect, because it must observe the
 * *next* charger connection even when the app is closed. It only shuts down
 * when the user turns the charge alarm off (`stopBackgroundMonitoring`).
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

    /**
     * The target percentage the alarm has already been fired for during the
     * current charging session, or `null` when no alarm is owed.
     *
     * Tracking the *target value* rather than a plain "already fired" boolean
     * is what makes both of these work: raising the target (80 -> 90) while
     * still charging re-arms at the new value, and lowering it below the
     * current level sounds rather than staying silently disarmed.
     */
    private var notifiedTarget: Int? = null

    /** Whether this service instance is currently the one holding the
     * sounding alarm, so we can silence it without a needless no-op on every
     * battery broadcast. */
    private var alarmSounding = false

    private var lastWasCharging = false

    companion object {
        private const val TAG = "ChargeMonitorService"
        private const val STATUS_CHANNEL_ID = "charge_monitor_status_channel"
        private const val STATUS_NOTIFICATION_ID = 2001

        /**
         * Starts the foreground service, swallowing the two failures Android
         * can throw here: [ForegroundServiceStartNotAllowedException] (API 31+)
         * when a manifest receiver fires while the app is not in a permitted
         * state, and any transient `IllegalStateException`. An uncaught
         * exception in a [BroadcastReceiver.onReceive] kills the whole app
         * process, which is exactly the failure this guards against. The
         * service is (re)started from a permitted context soon after — on the
         * next app launch or settings change — so skipping one attempt is safe.
         */
        fun start(context: Context) {
            val intent = Intent(context, ChargeMonitorService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (error: Exception) {
                Log.w(TAG, "Could not start ChargeMonitorService from this context.", error)
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, ChargeMonitorService::class.java))
            } catch (error: Exception) {
                Log.w(TAG, "Could not stop ChargeMonitorService.", error)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        promoteToForeground()
        registerBatteryReceiver()
        // Evaluate the state we're in right now, in case the service was
        // just (re)started while already above target (edge case: "device
        // reboot" / "app process killed" while charging).
        onReading(BatteryReadingUtils.currentSticky(this))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == AlarmPlugin.ACTION_STOP_ALARM) {
            AlarmPlugin.stopAlarm(this)
            alarmSounding = false
            notifiedTarget = null
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
        receiver = null
        super.onDestroy()
    }

    private fun promoteToForeground() {
        val notification = buildStatusNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // API 34+ requires the type to be declared at promotion time.
                ServiceCompat.startForeground(
                    this,
                    STATUS_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(STATUS_NOTIFICATION_ID, notification)
            }
        } catch (error: Exception) {
            // Foreground promotion can be refused when the app is considered
            // to be running in the background under an OEM's custom policy.
            // Monitoring continues without the persistent notification; the
            // runtime battery receiver below is unaffected.
            Log.w(TAG, "Foreground promotion refused; monitoring continues.", error)
        }
    }

    private fun registerBatteryReceiver() {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                try {
                    onReading(BatteryReadingUtils.fromIntent(intent))
                } catch (error: Exception) {
                    // One malformed reading must never take the process down.
                    Log.e(TAG, "Could not process battery reading.", error)
                }
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

        if (!isCharging) {
            // Charger unplugged: close out this charging session. Clearing the
            // notified target here is what makes "unplug then plug back in
            // while still above target" sound again — a fresh session is
            // allowed to fire for the first time.
            notifiedTarget = null
            lastWasCharging = false
            if (BatteryReadingUtils.autoStopOnUnplug(this)) {
                AlarmPlugin.stopAlarm(this)
                alarmSounding = false
            }
            // Deliberately no stopSelf(): the service stays alive so the next
            // ACTION_POWER_CONNECTED is observed even when the app is not
            // running at all.
            return
        }

        if (!lastWasCharging) {
            // First reading of a brand-new charging session.
            notifiedTarget = null
        }
        lastWasCharging = true

        if (!BatteryReadingUtils.isAlarmEnabled(this)) {
            // The user turned the charge alarm off: never alarm from here on,
            // and silence anything already sounding right now.
            notifiedTarget = null
            if (alarmSounding || AlarmPlugin.isPlaying) {
                AlarmPlugin.stopAlarm(this)
                alarmSounding = false
            }
            return
        }

        val target = BatteryReadingUtils.targetPercentage(this)
        when {
            reading.percentage >= target && notifiedTarget != target -> {
                notifiedTarget = target
                alarmSounding = true
                AlarmPlugin.startAlarm(
                    this,
                    BatteryReadingUtils.soundId(this),
                    BatteryReadingUtils.vibrationEnabled(this),
                    reading.percentage,
                )
            }
            reading.percentage >= target -> {
                // Already announced for this exact target; keep sounding but
                // never re-trigger ("do not repeatedly trigger the same alarm").
            }
            else -> {
                // Below target: if the target was raised above our current
                // level, disarm so the new, higher target can still fire.
                notifiedTarget = null
            }
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
