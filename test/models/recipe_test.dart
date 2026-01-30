import 'package:flutter_test/flutter_test.dart';
import 'package:drip_logger/models/recipe.dart';
import 'package:drip_logger/models/brew_step.dart'; // Stepも使うのでimport

void main() {
  group('Recipe Model Tests', () {
    test('should encode/decode correctly', () {
      // 1. テストデータ（期待値）を用意
      final originalReview = Recipe(
        id: 'test-id-1',
        name: 'Test Recipe',
        beanWeightGrams: 20,
        grindSize: 'Medium',
        totalWaterAmount: 300,
        steps: [
          BrewStep(waterAmount: 50, waitTime: const Duration(seconds: 30)),
        ],
        note: 'Test Note',
        lastUsed: DateTime(2023, 1, 1),
      );

      // 2. JSONに変換 (Encode)
      final jsonMap = originalReview.toJson();

      // 3. JSONから復元 (Decode)
      final decodedRecipe = Recipe.fromJson(jsonMap);

      // 4. 検証 (Assert)
      expect(decodedRecipe.id, originalReview.id);
      expect(decodedRecipe.name, originalReview.name);
      expect(decodedRecipe.beanWeightGrams, originalReview.beanWeightGrams);
      // 日時は文字変換を経由するので、Stringとして一致するか確認するのが無難
      expect(decodedRecipe.lastUsed.toIso8601String(),
          originalReview.lastUsed.toIso8601String());

      // Stepの中身も軽くチェック
      expect(decodedRecipe.steps.length, 1);
      expect(decodedRecipe.steps.first.waterAmount, 50);
    });
  });
}
