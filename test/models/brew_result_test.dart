import 'package:flutter_test/flutter_test.dart';
import 'package:drip_logger/models/brew_result.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/models/bean.dart';

void main() {
  group('BrewResult Model Tests', () {
    test('should generate correct Markdown', () {
      final recipe = Recipe(
        id: 'r1',
        name: 'My V60',
        beanWeightGrams: 15,
        grindSize: 'Medium',
        totalWaterAmount: 225,
        steps: [],
      );

      final bean = Bean(
        id: 'b1',
        name: 'Kenya AA',
        roastLevel: 'Medium',
      );

      final result = BrewResult(
        id: 'res1',
        recipe: recipe,
        bean: bean,
        brewedAt: DateTime(2023, 10, 1, 15, 30),
        totalTime: const Duration(minutes: 2, seconds: 45),
        steps: [
          BrewResultStep(
            stepIndex: 0,
            plannedTime: const Duration(seconds: 30),
            actualTime: const Duration(seconds: 32),
            waterAmount: 40,
          ),
        ],
        notes: 'Great acidity',
      );

      final md = result.toMarkdown();

      expect(md, contains('# My V60'));
      expect(md, contains('**抽出日**: 2023/10/01'));
      expect(md, contains('**合計時間**: 2:45'));
      expect(md, contains('**名称**: Kenya AA'));
      expect(md, contains('Great acidity'));
      // | Step | x ml | plan s | actual s | diff |
      // Format: | 1 | 40.0ml | 30s | 32s | +2s |
      expect(md, contains('| 1 | 40.0ml | 30s | 32s | +2s |'));
    });
  });
}
