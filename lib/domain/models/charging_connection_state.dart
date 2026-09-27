/// Represents whether a charger is physically connected to the device,
/// independent of whether the battery is actively gaining charge.
enum ChargingConnectionState {
  /// No charger/cable is connected.
  disconnected,

  /// A charger is connected and the battery is charging.
  charging,

  /// A charger is connected but the OS reports the battery as full
  /// (topped-off / trickle state), common once 100% is reached.
  connectedFull,
}
