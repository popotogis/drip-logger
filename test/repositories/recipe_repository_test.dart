import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:drip_logger/services/database_service.dart';
import 'package:drip_logger/repositories/recipe_repository.dart';
import 'package:drip_logger/models/recipe.dart';

void main() {
  late RecipeRepository repository;
  late DatabaseService databaseService;

  group('recipeRepository Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Use in-memory database for testing
      databaseService = DatabaseService(factory: databaseFactoryMemory);
      // Ensure clean state by deleting the DB from memory
      await databaseFactoryMemory.deleteDatabase('drip_logger.db');

      repository = RecipeRepository(databaseService);
    });

    test('loadRecipes returns defaults when empty', () async {
      final recipes = await repository.loadRecipes();

      expect(recipes.length, 2);
      expect(recipes.first.name, '4:6 Method');
    });

    test('saveRecipe and loadRecipes works correctly', () async {
      final testRecipe = Recipe(
        id: 'test-1',
        name: 'New Test Recipe',
        beanWeightGrams: 15,
        grindSize: 'Medium',
        totalWaterAmount: 225,
        steps: [],
      );

      await repository.saveRecipe(testRecipe);
      final loadedRecipes = await repository.loadRecipes();

      // Defaults + New Recipe = 3
      // But wait, loadRecipes returns defaults ONLY if DB is empty.
      // If we save prior to loading, loadRecipes checks migration.
      // 1. SharedPreferences empty -> migration skipped.
      // 2. DB has 1 record (saved above).
      // 3. loadRecipes returns standard find result (1 record).
      //
      // However, if we call `loadRecipes` FIRST in previous test, it seeds defaults?
      // No, `loadRecipes` code: if snapshots.isEmpty -> return defaults (but doesn't save them? Let's check impl).
      // Impl: if (snapshots.isEmpty) return _generateDefaultRecipes(); -> It does NOT save them to DB.
      // So if we save 1 recipe, DB has 1. loadRecipes returns 1.
      expect(loadedRecipes.length, 1);
      expect(loadedRecipes.first.id, 'test-1');
      expect(loadedRecipes.first.name, 'New Test Recipe');
    });
  });
}
