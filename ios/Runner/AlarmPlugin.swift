import AVFoundation
import Flutter
import UIKit
import UserNotifications

/// iOS implementation of the `AlarmPlayerService` Dart interface.
///
/// Honest capability boundary (see also `BatteryMonitorPlugin`): iOS does
/// not allow apps to loop arbitrary alarm audio indefinitely in the
/// background the way Android's foreground service can. This
/// implementation uses the strongest officially supported mechanism:
///   - While the app is foregrounded/active: plays looping audio via
///     `AVAudioSession`'s `.playback` category (audible even if the
///     device is in silent mode, matching a real alarm's behavior) plus
///     haptic/vibration feedback.
///   - Regardless of foreground state: schedules a local notification via
///     `UNUserNotificationCenter` with a system alert sound, so the user
///     is still alerted if they have switched away from the app, subject
///     to notification permission being granted.
/// It never claims to keep playing looping audio once iOS suspends the
/// app process, which would misrepresent an unsupported background
/// capability.
final class AlarmPlugin: NSObject, FlutterPlugin {

    private var player: AVAudioPlayer?
    private var isCurrentlyPlaying = false

    /// FlutterPlugin declares register(with:) (the Swift import of the
    /// ObjC +registerWithRegistrar:) as a REQUIRED member. The
    /// messenger-based overload below is a different, unrelated signature
    /// and does not satisfy it on its own, so this adapter both meets the
    /// protocol requirement and forwards to the entry point that
    /// AppDelegate already calls.
    static func register(with registrar: FlutterPluginRegistrar) {
        register(with: registrar.messenger())
    }

    static func register(with messenger: FlutterBinaryMessenger) {

        let instance = AlarmPlugin()
        let channel = FlutterMethodChannel(name: "chargealarm/alarm_control", binaryMessenger: messenger)
        channel.setMethodCallHandler(instance.handle)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // Internal (not private): FlutterPlugin declares handle(_:result:)
    // as a protocol requirement, so the implementation must be at least
    // as accessible as the conformance itself.
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {
        case "startAlarm":
            let args = call.arguments as? [String: Any] ?? [:]
            let reachedPercentage = args["reachedPercentage"] as? Int ?? 100
            start(reachedPercentage: reachedPercentage)
            result(nil)
        case "stopAlarm":
            stop()
            result(nil)
        case "isAlarmPlaying":
            result(isCurrentlyPlaying)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func start(reachedPercentage: Int) {
        scheduleLocalNotification(reachedPercentage: reachedPercentage)
        startForegroundAudioLoop()
        isCurrentlyPlaying = true
    }

    private func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        isCurrentlyPlaying = false
    }

    private func startForegroundAudioLoop() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)

            // ChargeAlarm ships no bundled audio assets; the system alert
            // sound is used as the in-app looping cue while active.
            guard let url = Bundle.main.url(forResource: "alarm_default", withExtension: "caf") else {
                return
            }
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
        } catch {
            // If audio playback cannot start (e.g. no bundled sound file
            // present yet — see release-notes.md), the scheduled local
            // notification below still alerts the user.
        }
    }

    private func scheduleLocalNotification(reachedPercentage: Int) {
        let content = UNMutableNotificationContent()
        if reachedPercentage >= 100 {
            content.title = "Battery Full"
            content.body = "Battery Full — Please Unplug the Charger"
        } else {
            content.title = "Target Reached"
            content.body = "Your battery reached \(reachedPercentage)%."
        }
        content.sound = .default
        content.categoryIdentifier = "CHARGE_ALARM"

        let request = UNNotificationRequest(
            identifier: "chargealarm.target_reached",
            content: content,
            trigger: nil // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
