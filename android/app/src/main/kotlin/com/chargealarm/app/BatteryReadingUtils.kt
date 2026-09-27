package com.chargealarm.app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager

/**
 * Shared helpers for turning a raw ACTION_BATTERY_CHANGED [Intent] into the
 * `(percentage, connectionState)` shape the Dart side expects, plus the tiny
 * SharedPreferences bridge used to read settings written by the Flutter
 * `shared_preferences` plugin from purely-native code paths (the foreground
 * service and boot/charging broadcast receivers, which may run without a
 * live Flutter engine).
 */
object BatteryReadingUtils {

    const val STATE_DISCONNECTED = "disconnected"
    const val STATE_CHARGING = "charging"
    const val STATE_CONNECTED_FULL = "connectedFull"

    data class Reading(val percentage: Int, val connectionState: String, val timestampMs: Long)

    fun currentSticky(context: Context): Reading {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val intent = context.registerReceiver(null, filter)
        return fromIntent(intent)
    }

    fun fromIntent(intent: Intent?): Reading {
        if (intent == null) {
            return Reading(0, STATE_DISCONNECTED, System.currentTimeMillis())
        }
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val percentage = if (level >= 0 && scale > 0) (level * 100 / scale).coerceIn(0, 100) else 0

        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val pluggedInt = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val isPlugged = pluggedInt != 0

        val connectionState = when {
            !isPlugged -> STATE_DISCONNECTED
            status == BatteryManager.BATTERY_STATUS_FULL -> STATE_CONNECTED_FULL
            else -> STATE_CHARGING
        }

        return Reading(percentage, connectionState, System.currentTimeMillis())
    }

    /** Reads a value written by Flutter's `shared_preferences` plugin, which
     * stores everything in the `FlutterSharedPreferences` file with an
     * `flutter.` key prefix. Kept in one place so every native entry point
     * (service, receivers) agrees with [SettingsRepositoryImpl] on where
     * persisted settings live. */
    private fun prefs(context: Context) =
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    fun isAlarmEnabled(context: Context): Boolean =
        prefs(context).getBoolean("flutter.alarm_enabled", true)

    fun targetPercentage(context: Context): Int =
        prefs(context).getInt("flutter.target_percentage", 80).coerceIn(1, 100)

    fun soundId(context: Context): String =
        prefs(context).getString("flutter.sound_id", "default_alarm") ?: "default_alarm"

    fun vibrationEnabled(context: Context): Boolean =
        prefs(context).getBoolean("flutter.vibration_enabled", true)

    fun autoStopOnUnplug(context: Context): Boolean =
        prefs(context).getBoolean("flutter.auto_stop_on_unplug", true)
}
