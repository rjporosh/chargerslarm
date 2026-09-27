package com.chargealarm.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Single Flutter host activity. Plugin registration is handled by
 * [BatteryMonitorPlugin] and [AlarmPlugin] themselves via the standard
 * FlutterPlugin lifecycle, so this class only needs to wire them in.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(BatteryMonitorPlugin())
        flutterEngine.plugins.add(AlarmPlugin())
    }
}
