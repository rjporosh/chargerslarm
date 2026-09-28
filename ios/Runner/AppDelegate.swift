import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register the framework-owned plugins first so they are available
        // before the app's own plugins, then register the two app-owned
        // battery/alarm plugins on the same messenger the engine owns.
        // The root view controller is conditionally (not force) cast so an
        // unexpected launch configuration can never crash startup.
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window?.rootViewController as? FlutterViewController {
            BatteryMonitorPlugin.register(with: controller.binaryMessenger)
            AlarmPlugin.register(with: controller.binaryMessenger)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
