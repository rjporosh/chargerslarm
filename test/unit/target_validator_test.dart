import 'package:chargealarm/domain/logic/target_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = TargetValidator();

  group('TargetValidator.validate', () {
    test('accepts the minimum boundary (1)', () {
      expect(validator.validate(1).isValid, isTrue);
    });

    test('accepts the maximum boundary (100)', () {
      expect(validator.validate(100).isValid, isTrue);
    });

    test('accepts a typical mid-range value', () {
      expect(validator.validate(80).isValid, isTrue);
    });

    test('rejects zero', () {
      final result = validator.validate(0);
      expect(result.isValid, isFalse);
      expect(result.errorKey, 'errorTargetOutOfRange');
    });

    test('rejects negative values', () {
      expect(validator.validate(-5).isValid, isFalse);
    });

    test('rejects values above 100', () {
      expect(validator.validate(101).isValid, isFalse);
    });

    test('rejects null with a distinct error key', () {
      final result = validator.validate(null);
      expect(result.isValid, isFalse);
      expect(result.errorKey, 'errorTargetRequired');
    });
  });

  group('TargetValidator.clamp', () {
    test('leaves in-range values untouched', () {
      expect(validator.clamp(42), 42);
    });

    test('clamps below-range values up to the minimum', () {
      expect(validator.clamp(-10), 1);
      expect(validator.clamp(0), 1);
    });

    test('clamps above-range values down to the maximum', () {
      expect(validator.clamp(250), 100);
    });
  });
}
