package com.chargealarm.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.os.CombinedVibration

/**
 * Flutter-facing bridge for [AlarmPlayerService]. Actual playback lives in
 * the top-level companion functions so [ChargeMonitorService] can trigger
 * or stop the exact same alarm from a pure background context, with no
 * Flutter engine required — this is what lets ChargeAlarm fire while the
 * app process has been killed by the OS, as long as Android itself keeps
 * the foreground service alive.
 */
class AlarmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "chargealarm/alarm_control")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startAlarm" -> {
                val soundId = call.argument<String>("soundId") ?: "default_alarm"
                val vibrationEnabled = call.argument<Boolean>("vibrationEnabled") ?: true
                val reachedPercentage = call.argument<Int>("reachedPercentage") ?: 100
                startAlarm(context, soundId, vibrationEnabled, reachedPercentage)
                result.success(null)
            }
            "stopAlarm" -> {
                stopAlarm(context)
                result.success(null)
            }
            "isAlarmPlaying" -> result.success(isPlaying)
            else -> result.notImplemented()
        }
    }

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "charge_alarm_channel"
        const val ALARM_NOTIFICATION_ID = 1001
        const val ACTION_STOP_ALARM = "com.chargealarm.app.ACTION_STOP_ALARM"

        @Volatile
        var isPlaying: Boolean = false
            private set

        private var mediaPlayer: MediaPlayer? = null

        /** Resolves a persisted sound id to a real system alarm/notification
         * sound URI. ChargeAlarm ships no bundled audio assets of its own
         * (see release-notes.md); each option maps to a distinct system
         * ringtone category so choices remain audibly different. */
        private fun soundUriFor(soundId: String) = when (soundId) {
            "gentle_chime" -> RingtoneManager.getActualDefaultRingtoneUri(
                null, RingtoneManager.TYPE_NOTIFICATION,
            ) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            "urgent_alert" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            "classic_bell" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
        }

        private fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(NOTIFICATION_CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "Charge alarm",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Alerts when your device reaches the target charge level."
                    enableVibration(false) // vibration handled explicitly, respecting the user setting
                    setSound(
                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                }
                manager.createNotificationChannel(channel)
            }
        }

        fun startAlarm(context: Context, soundId: String, vibrationEnabled: Boolean, reachedPercentage: Int) {
            ensureChannel(context)
            postAlarmNotification(context, reachedPercentage)
            playSound(context, soundId)
            if (vibrationEnabled) vibrate(context)
            isPlaying = true
        }

        fun stopAlarm(context: Context) {
            mediaPlayer?.let {
                try {
                    if (it.isPlaying) it.stop()
                } finally {
                    it.release()
                }
            }
            mediaPlayer = null
            stopVibration(context)
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.cancel(ALARM_NOTIFICATION_ID)
            isPlaying = false
        }

        private fun playSound(context: Context, soundId: String) {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                setDataSource(context, soundUriFor(soundId))
                isLooping = true
                setOnPreparedListener { it.start() }
                prepareAsync()
            }
        }

        private fun vibrate(context: Context) {
            val pattern = longArrayOf(0, 800, 400, 800, 400, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = context.getSystemService(VibratorManager::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    val manager = context.getSystemService(VibratorManager::class.java)
    manager.vibrate(
        CombinedVibration.createParallel(
            VibrationEffect.createWaveform(pattern, 0)
        )
    )
}

            } else {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(pattern, 0)
                }
            }
        }

        private fun stopVibration(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java).cancel()
            } else {
                @Suppress("DEPRECATION")
                (context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).cancel()
            }
        }

        private fun postAlarmNotification(context: Context, reachedPercentage: Int) {
            val stopIntent = Intent(context, ChargeMonitorService::class.java).apply {
                action = ACTION_STOP_ALARM
            }
            val stopPendingIntent = PendingIntent.getService(
                context, 0, stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val contentPendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val title = if (reachedPercentage >= 100) "Battery Full" else "Target Reached"
            val text = if (reachedPercentage >= 100) {
                "Battery Full — Please Unplug the Charger"
            } else {
                "Your battery reached $reachedPercentage%."
            }

            val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_lock_idle_charging)
                .setContentTitle(title)
                .setContentText(text)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setOngoing(true)
                .setAutoCancel(false)
                .setContentIntent(contentPendingIntent)
                .addAction(0, "Stop Alarm", stopPendingIntent)
                .build()

            val manager = context.getSystemService(NotificationManager::class.java)
            manager.notify(ALARM_NOTIFICATION_ID, notification)
        }
    }
}
