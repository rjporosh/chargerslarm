package com.chargealarm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Manifest-registered receiver for the two *explicit* charging broadcasts
 * Android still delivers to statically declared receivers post-API 26
 * (ACTION_BATTERY_CHANGED itself cannot be, which is why the moment-to-
 * moment percentage stream is instead read inside [ChargeMonitorService]
 * via a runtime-registered receiver). This receiver's only job is to
 * start/stop that foreground service in response to the charger being
 * connected or disconnected, including when the app process is not
 * currently running at all.
 */
class ChargingBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_POWER_CONNECTED -> {
                if (BatteryReadingUtils.isAlarmEnabled(context)) {
                    ChargeMonitorService.start(context)
                }
            }
            Intent.ACTION_POWER_DISCONNECTED -> {
                // ChargeMonitorService also stops itself once it observes the
                // disconnect via its own battery receiver; this is a
                // best-effort early stop for cases where the service never
                // started (e.g. alarm was disabled when charging began).
                if (BatteryReadingUtils.autoStopOnUnplug(context)) {
                    AlarmPlugin.stopAlarm(context)
                }
            }
        }
    }
}
