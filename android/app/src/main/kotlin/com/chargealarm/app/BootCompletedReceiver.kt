package com.chargealarm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts monitoring after a device reboot if the phone happens to already
 * be connected to power when it comes back up (edge case: "device reboot
 * where supported"). Android does not preserve foreground services across
 * reboot, so this is required to recover that state.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!BatteryReadingUtils.isAlarmEnabled(context)) return

        val reading = BatteryReadingUtils.currentSticky(context)
        if (reading.connectionState != BatteryReadingUtils.STATE_DISCONNECTED) {
            ChargeMonitorService.start(context)
        }
    }
}
