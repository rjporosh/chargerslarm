/// Lifecycle state of the alarm itself, distinct from the battery/charging
/// state. Drives dashboard UI and whether native alarm playback is active.
enum AlarmStatus {
  /// No target reached yet; alarm is armed but silent.
  idle,

  /// Target has been reached and the alarm is actively sounding.
  sounding,

  /// The alarm was reached and then dismissed/stopped by the user or by
  /// auto-stop-on-unplug; will re-arm on the next charging session.
  dismissed,

  /// Alarm is disabled in settings; no monitoring feedback is surfaced.
  disabled,
}
