import 'package:flutter_test/flutter_test.dart';
import 'package:drip_logger/models/brew_step.dart';

void main() {
  group('BrewStep Tests', () {
    test('Default constructor creates a pour step', () {
      final step = BrewStep(
        waterAmount: 50,
        waitTime: const Duration(seconds: 30),
      );

      expect(step.type, BrewStepType.pour);
      expect(step.waterAmount, 50);
      expect(step.waitTime.inSeconds, 30);
      expect(step.description, null);
    });

    test('Can create wait step', () {
      final step = BrewStep(
        type: BrewStepType.wait,
        waterAmount: 0,
        waitTime: const Duration(seconds: 45),
        description: 'Pause for bloom',
      );

      expect(step.type, BrewStepType.wait);
      expect(step.waterAmount, 0);
      expect(step.waitTime.inSeconds, 45);
      expect(step.description, 'Pause for bloom');
    });

    test('Json serialization works correctly', () {
      final step = BrewStep(
        type: BrewStepType.stir,
        waterAmount: 0,
        waitTime: const Duration(seconds: 10),
        description: 'Stir gently',
      );

      final json = step.toJson();
      expect(json['type'], 'stir');
      expect(json['waterAmount'], 0.0);
      expect(json['waitTime'], 10);
      expect(json['description'], 'Stir gently');

      final reconstructed = BrewStep.fromJson(json);
      expect(reconstructed.type, BrewStepType.stir);
      expect(reconstructed.waterAmount, 0);
      expect(reconstructed.waitTime.inSeconds, 10);
      expect(reconstructed.description, 'Stir gently');
    });

    test('Scale check ensures type and description are preserved', () {
      final step = BrewStep(
        type: BrewStepType.pour,
        waterAmount: 50,
        waitTime: const Duration(seconds: 30),
        description: 'First pour',
      );

      final scaled = step.scale(1.5);
      // 50 * 1.5 = 75
      expect(scaled.waterAmount, 75);
      expect(scaled.waitTime.inSeconds, 30); // waitTime is not scaled
      expect(scaled.type, BrewStepType.pour);
      expect(scaled.description, 'First pour');
    });

    test('Scale wait step preserves zero water amount', () {
      final step = BrewStep(
        type: BrewStepType.wait,
        waterAmount: 0,
        waitTime: const Duration(seconds: 30),
        description: 'Wait',
      );

      final scaled = step.scale(2.0);
      expect(scaled.waterAmount, 0);
      expect(scaled.waitTime.inSeconds, 30);
      expect(scaled.type, BrewStepType.wait);
      expect(scaled.description, 'Wait');
    });
  });
}
