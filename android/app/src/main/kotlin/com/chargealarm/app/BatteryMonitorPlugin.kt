package com.chargealarm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter-facing bridge for [BatteryMonitorService] (Dart interface).
 * Registers:
 *  - a MethodChannel for one-shot reads and background-monitoring control
 *  - an EventChannel that streams a reading on every ACTION_BATTERY_CHANGED
 *    broadcast while the Flutter engine is alive (foreground use)
 *
 * The [ChargeMonitorService] also holds an optional reference to
 * [activeSink] so it can push readings straight into a running Flutter UI
 * even while it is the one that owns the underlying receiver — but the
 * service never *depends* on the engine being alive; see its own
 * documentation for the native-only alarm path used when it is not.
 */
class BatteryMonitorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var receiver: BroadcastReceiver? = null

    companion object {
        /** Live sink for the current Flutter engine, if any. Written/cleared
         * only from the main thread by this plugin's own lifecycle. */
        var activeSink: EventChannel.EventSink? = null
            private set
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "chargealarm/battery_control")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "chargealarm/battery_stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        unregisterReceiver()
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentReading" -> {
                val reading = BatteryReadingUtils.currentSticky(context)
                result.success(
                    mapOf(
                        "percentage" to reading.percentage,
                        "connectionState" to reading.connectionState,
                        "timestampMs" to reading.timestampMs,
                    ),
                )
            }
            "startBackgroundMonitoring" -> {
                ChargeMonitorService.start(context)
                result.success(null)
            }
            "stopBackgroundMonitoring" -> {
                ChargeMonitorService.stop(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        activeSink = events
        // Emit the current sticky state immediately so the UI never shows a
        // blank dashboard while waiting for the next OS broadcast (covers
        // "app launched while already charging").
        val initial = BatteryReadingUtils.currentSticky(context)
        events.success(
            mapOf(
                "percentage" to initial.percentage,
                "connectionState" to initial.connectionState,
                "timestampMs" to initial.timestampMs,
            ),
        )

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                val reading = BatteryReadingUtils.fromIntent(intent)
                activeSink?.success(
                    mapOf(
                        "percentage" to reading.percentage,
                        "connectionState" to reading.connectionState,
                        "timestampMs" to reading.timestampMs,
                    ),
                )
            }
        }
        context.registerReceiver(receiver, filter)
    }

    override fun onCancel(arguments: Any?) {
        activeSink = null
        unregisterReceiver()
    }

    private fun unregisterReceiver() {
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                // Already unregistered — safe to ignore.
            }
        }
        receiver = null
    }
}
