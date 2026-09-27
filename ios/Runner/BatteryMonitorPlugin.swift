import Flutter
import UIKit

/// iOS implementation of the `BatteryMonitorService` Dart interface, backed
/// by `UIDevice.current.batteryLevel` / `batteryState` monitoring.
///
/// Platform reality this class is honest about: iOS only delivers battery
/// notifications while the app process is alive (foreground or briefly
/// backgrounded); there is no supported API for an indefinitely-running
/// background battery monitor on iOS, unlike Android's foreground service.
/// ChargeAlarm therefore keeps monitoring for as long as iOS keeps the app
/// process alive (foreground, and the short background execution window
/// after entering background), and relies on a local notification,
/// scheduled the moment the target is reached, to alert the user even if
/// they have since switched apps — but it will not detect the target being
/// reached after the OS has fully suspended/terminated the process. This
/// limitation is documented for the user in Settings and in README.md.
final class BatteryMonitorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?

    static func register(with messenger: FlutterBinaryMessenger) {
        let instance = BatteryMonitorPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "chargealarm/battery_control", binaryMessenger: messenger)
        methodChannel.setMethodCallHandler(instance.handle)

        let eventChannel = FlutterEventChannel(
            name: "chargealarm/battery_stream", binaryMessenger: messenger)
        eventChannel.setStreamHandler(instance)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCurrentReading":
            UIDevice.current.isBatteryMonitoringEnabled = true
            result(Self.currentReadingMap())
        case "startBackgroundMonitoring":
            // Best-effort only; see class documentation above. iOS does not
            // offer an equivalent to Android's foreground service here.
            UIDevice.current.isBatteryMonitoringEnabled = true
            result(nil)
        case "stopBackgroundMonitoring":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        UIDevice.current.isBatteryMonitoringEnabled = true
        eventSink = events
        events(Self.currentReadingMap())

        NotificationCenter.default.addObserver(
            self, selector: #selector(onBatteryChange),
            name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(onBatteryChange),
            name: UIDevice.batteryStateDidChangeNotification, object: nil)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }

    @objc private func onBatteryChange() {
        eventSink?(Self.currentReadingMap())
    }

    private static func currentReadingMap() -> [String: Any] {
        let device = UIDevice.current
        let rawLevel = device.batteryLevel // -1.0 if unknown
        let percentage = rawLevel < 0 ? 0 : Int((rawLevel * 100).rounded())

        let connectionState: String
        switch device.batteryState {
        case .charging:
            connectionState = "charging"
        case .full:
            connectionState = "connectedFull"
        case .unplugged, .unknown:
            connectionState = "disconnected"
        @unknown default:
            connectionState = "disconnected"
        }

        return [
            "percentage": percentage,
            "connectionState": connectionState,
            "timestampMs": Int(Date().timeIntervalSince1970 * 1000),
        ]
    }
}
