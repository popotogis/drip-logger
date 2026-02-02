import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drip_logger/repositories/recipe_repository.dart';
import 'package:drip_logger/models/recipe.dart';

void main() {
  late RecipeRepository repository;

  group('recipeRepository Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = RecipeRepository();
    });

    test('loadRecipes returns defaults when empty', () async {
      final recipes = await repository.loadRecipes();

      expect(recipes.length, 2);
      expect(recipes.first.name, '4:6 Method');
    });

    test('saveRecipes and loadRecipes works correctly', () async {
      final testRecipe = Recipe(
        id: 'test-1',
        name: 'New Test Recipe',
        beanWeightGrams: 15,
        grindSize: 'Medium',
        totalWaterAmount: 225,
        steps: [],
      );

      await repository.saveRecipes([testRecipe]);
      final loadedRecipes = await repository.loadRecipes();

      expect(loadedRecipes.length, 1);
      expect(loadedRecipes.first.id, 'test-1');
      expect(loadedRecipes.first.name, 'New Test Recipe');
    });
  });
}
