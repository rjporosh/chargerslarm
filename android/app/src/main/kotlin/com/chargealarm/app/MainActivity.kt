package com.chargealarm.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
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
        requestNotificationPermissionIfNeeded()
    }

    /**
     * POST_NOTIFICATIONS is declared in the manifest but must also be granted
     * at runtime on Android 13+. Without it the alarm notification and the
     * charge-monitoring foreground-service notification are suppressed, which
     * makes the alarm look "broken" even though the audio still plays.
     */
    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return

        val alreadyGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED

        if (!alreadyGranted) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST_CODE,
            )
        }
    }

    private companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4001
    }
}
