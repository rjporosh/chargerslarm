/// A sound option the user can pick for the charge alarm.
///
/// [id] is a stable identifier persisted to settings and passed to the
/// native platform layer to resolve the actual audio resource; it must
/// never change once shipped, or persisted user preferences will break.
class AlarmSound {
  const AlarmSound({required this.id, required this.labelKey});

  final String id;

  /// Key into the localization resources for the display name of this
  /// sound (sound names are not free text, so they can be localized too).
  final String labelKey;

  static const default_ = AlarmSound(id: 'default_alarm', labelKey: 'soundDefault');
  static const gentle = AlarmSound(id: 'gentle_chime', labelKey: 'soundGentleChime');
  static const urgent = AlarmSound(id: 'urgent_alert', labelKey: 'soundUrgentAlert');
  static const classic = AlarmSound(id: 'classic_bell', labelKey: 'soundClassicBell');

  static const List<AlarmSound> all = [default_, gentle, urgent, classic];

  static AlarmSound fromId(String id) {
    return all.firstWhere((s) => s.id == id, orElse: () => default_);
  }
}
