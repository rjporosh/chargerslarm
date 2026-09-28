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

    private const val DEFAULT_TARGET_PERCENTAGE = 80
    private const val DEFAULT_SOUND_ID = "default_alarm"

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
     * stores everything in the `FlutterSharedPreferences` file with a
     * `flutter.` key prefix. Kept in one place so every native entry point
     * (service, receivers) agrees with [SettingsRepositoryImpl] on where
     * persisted settings live. */
    private fun prefs(context: Context) =
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    /**
     * Reads a single persisted value by *type inspection* rather than through
     * `getInt`/`getBoolean`/`getString`.
     *
     * Flutter's `shared_preferences` plugin serialises every Dart `int` as a
     * Java `Long`, because Dart integers are 64-bit. Calling
     * `SharedPreferences.getInt("flutter.target_percentage")` on such a value
     * throws `ClassCastException: java.lang.Long cannot be cast to
     * java.lang.Integer`, which took down [ChargeMonitorService] and, via
     * START_STICKY, the whole app process in a loop. Inspecting the stored
     * type keeps this bridge compatible with whichever representation the
     * plugin chooses to write, and defaults safely if the value is absent or
     * malformed.
     */
    private fun raw(context: Context, key: String): Any? =
        prefs(context).all["flutter.$key"]

    private fun readBoolean(context: Context, key: String, fallback: Boolean): Boolean =
        when (val value = raw(context, key)) {
            is Boolean -> value
            is String -> value.equals("true", ignoreCase = true)
            else -> fallback
        }

    private fun readLong(context: Context, key: String, fallback: Long): Long =
        when (val value = raw(context, key)) {
            is Long -> value
            is Int -> value.toLong()
            is Double -> value.toLong()
            is Float -> value.toLong()
            is String -> value.toLongOrNull() ?: fallback
            else -> fallback
        }

    private fun readString(context: Context, key: String, fallback: String): String =
        when (val value = raw(context, key)) {
            is String -> value
            null -> fallback
            else -> value.toString()
        }

    fun isAlarmEnabled(context: Context): Boolean =
        readBoolean(context, "alarm_enabled", true)

    fun targetPercentage(context: Context): Int =
        readLong(context, "target_percentage", DEFAULT_TARGET_PERCENTAGE.toLong())
            .toInt()
            .coerceIn(1, 100)

    fun soundId(context: Context): String =
        readString(context, "sound_id", DEFAULT_SOUND_ID)

    fun vibrationEnabled(context: Context): Boolean =
        readBoolean(context, "vibration_enabled", true)

    fun autoStopOnUnplug(context: Context): Boolean =
        readBoolean(context, "auto_stop_on_unplug", true)
}
