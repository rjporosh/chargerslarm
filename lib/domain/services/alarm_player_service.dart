import '../models/alarm_settings.dart';

/// Abstraction over native alarm playback: sound, vibration, and the
/// associated system notification. Kept separate from
/// [BatteryMonitorService] because playback has entirely different
/// platform primitives (AudioManager/AVAudioSession, notification
/// channels) and its own lifecycle.
abstract class AlarmPlayerService {
  /// Starts alarm playback (sound + vibration + notification) using the
  /// given settings, at the maximum capability the current platform and
  /// OS version permit. Safe to call again while already playing (e.g. to
  /// refresh the notification text) — implementations should not double
  /// up audio.
  Future<void> start({
    required AlarmSettings settings,
    required int reachedPercentage,
  });

  /// Stops any active alarm playback and clears the associated
  /// notification.
  Future<void> stop();

  /// True if the native side currently believes an alarm is playing.
  /// Useful for reconciling state after the app resumes from background.
  Future<bool> isPlaying();
}
