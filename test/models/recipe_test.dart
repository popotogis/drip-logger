import 'package:flutter_test/flutter_test.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/models/brew_step.dart';

void main() {
  group('Recipe Scaling Tests', () {
    late Recipe baseRecipe;

    setUp(() {
      baseRecipe = Recipe(
        id: 'test-1',
        name: 'Test Recipe',
        beanWeightGrams: 20.0,
        grindSize: 'Medium',
        totalWaterAmount: 300.0,
        steps: [
          BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 30)),
          BrewStep(waterAmount: 120, waitTime: const Duration(seconds: 60)),
          BrewStep(waterAmount: 120, waitTime: const Duration(seconds: 60)),
        ],
      );
    });

    test('scaleToBeanWeight should scale water and steps proportionally', () {
      // 20g -> 10g (0.5x)
      final scaled = baseRecipe.scaleToBeanWeight(10.0);

      expect(scaled.beanWeightGrams, 10.0);
      expect(scaled.totalWaterAmount, 150.0);
      expect(scaled.steps.length, 3);
      expect(scaled.steps[0].waterAmount, 30.0);
      expect(scaled.steps[1].waterAmount, 60.0);
    });

    test('scaleToBeanWeight should handle rounding correctly', () {
      // 20g -> 15g (0.75x)
      // 60 * 0.75 = 45
      // 120 * 0.75 = 90
      final scaled = baseRecipe.scaleToBeanWeight(15.0);

      expect(scaled.beanWeightGrams, 15.0);
      expect(scaled.totalWaterAmount, 225.0);
      expect(scaled.steps[0].waterAmount, 45.0);
    });

    test('isContentDifferent should detect changes', () {
      final modifiedBean = baseRecipe.copyWith(beanWeightGrams: 21.0);
      expect(baseRecipe.isContentDifferent(modifiedBean), isTrue);

      final modifiedStep = baseRecipe.copyWith(
        steps: [
          BrewStep(waterAmount: 61, waitTime: const Duration(seconds: 30)),
          baseRecipe.steps[1],
          baseRecipe.steps[2],
        ],
      );
      expect(baseRecipe.isContentDifferent(modifiedStep), isTrue);

      final sameRecipe = baseRecipe.copyWith();
      expect(baseRecipe.isContentDifferent(sameRecipe), isFalse);
    });

    test('floating point rounding in scaling', () {
      // Test with values that often cause precision issues
      final recipe = Recipe(
        id: 'f-1',
        name: 'Float Test',
        beanWeightGrams: 15.0,
        grindSize: 'M',
        totalWaterAmount: 225.0,
        steps: [
          BrewStep(waterAmount: 30.0, waitTime: Duration.zero),
          BrewStep(waterAmount: 195.0, waitTime: Duration.zero),
        ],
      );

      // Scale by 1/3 (ratio 0.33333...)
      final scaled = recipe.scaleByRatio(1 / 3);

      // Expected: 15 * 1/3 = 5.0
      expect(scaled.beanWeightGrams, 5.0);
      // Steps: 30 * 1/3 = 10, 195 * 1/3 = 65. Total = 75
      expect(scaled.steps[0].waterAmount, 10.0);
      expect(scaled.steps[1].waterAmount, 65.0);
      expect(scaled.totalWaterAmount, 75.0);
    });
  });
}
