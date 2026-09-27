/// Result of validating a candidate target percentage.
class TargetValidationResult {
  const TargetValidationResult._({required this.isValid, this.errorKey});

  const TargetValidationResult.valid() : this._(isValid: true);
  const TargetValidationResult.invalid(String errorKey)
      : this._(isValid: false, errorKey: errorKey);

  final bool isValid;

  /// Localization key describing why the value is invalid, if any.
  final String? errorKey;
}

/// Pure, platform-independent validation rules for the alarm target
/// percentage. Kept free of Flutter/UI concerns so it is trivially unit
/// testable and reusable from both the settings screen and persistence
/// layer (defence in depth against corrupted stored values).
class TargetValidator {
  const TargetValidator();

  static const int minTarget = 1;
  static const int maxTarget = 100;

  TargetValidationResult validate(int? candidate) {
    if (candidate == null) {
      return const TargetValidationResult.invalid('errorTargetRequired');
    }
    if (candidate < minTarget || candidate > maxTarget) {
      return const TargetValidationResult.invalid('errorTargetOutOfRange');
    }
    return const TargetValidationResult.valid();
  }

  /// Clamps an out-of-range value into the valid [minTarget, maxTarget]
  /// window. Used when sanitizing values coming from persistence or from
  /// native platform callbacks, where surfacing a hard error is not
  /// appropriate.
  int clamp(int candidate) {
    if (candidate < minTarget) return minTarget;
    if (candidate > maxTarget) return maxTarget;
    return candidate;
  }
}
