import 'package:flutter/services.dart';

import '../../domain/models/alarm_settings.dart';
import '../../domain/services/alarm_player_service.dart';

/// [AlarmPlayerService] implementation backed by a platform MethodChannel.
/// The native side is responsible for actually playing sound/vibration and
/// posting/updating the alarm notification, using each platform's maximum
/// permitted capability (Android: alarm-category notification + looping
/// media playback; iOS: local notification + foreground audio session,
/// since iOS does not allow arbitrary background alarm audio).
class NativeAlarmChannel implements AlarmPlayerService {
  NativeAlarmChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('chargealarm/alarm_control');

  final MethodChannel _channel;

  @override
  Future<void> start({
    required AlarmSettings settings,
    required int reachedPercentage,
  }) {
    return _channel.invokeMethod('startAlarm', {
      'soundId': settings.soundId,
      'vibrationEnabled': settings.vibrationEnabled,
      'reachedPercentage': reachedPercentage,
    });
  }

  @override
  Future<void> stop() {
    return _channel.invokeMethod('stopAlarm');
  }

  @override
  Future<bool> isPlaying() async {
    final result = await _channel.invokeMethod<bool>('isAlarmPlaying');
    return result ?? false;
  }
}
