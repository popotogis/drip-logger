import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';

class RecipeRepository {
  static const String _keyRecipes = 'recipes';

  // Load recipes from storage
  Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyRecipes);

    if (jsonString == null) {
      // Return default data if storage is empty
      return _generateDefaultRecipes();
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final recipes = jsonList.map((json) => Recipe.fromJson(json)).toList();
      recipes.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return recipes;
    } catch (e) {
      // If error (e.g. format change), return defaults or empty
      print('Error loading recipes: $e');
      return _generateDefaultRecipes();
    }
  }

  // Save recipes to storage
  Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        jsonEncode(recipes.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRecipes, jsonString);
  }

  Future<void> updateLastUsed(String recipeId) async {
    final recipes = await loadRecipes();
    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index != -1) {
      final old = recipes[index];
      final updated = Recipe(
          id: old.id,
          name: old.name,
          beanWeightGrams: old.beanWeightGrams,
          grindSize: old.grindSize,
          temperature: old.temperature,
          totalWaterAmount: old.totalWaterAmount,
          note: old.note,
          steps: old.steps,
          lastUsed: DateTime.now());

      recipes.removeAt(index);
      recipes.insert(0, updated);
      await saveRecipes(recipes);
    }
  }

  // Default Initial Data
  List<Recipe> _generateDefaultRecipes() {
    return [
      Recipe(
        id: '1',
        name: '4:6 Method',
        beanWeightGrams: 20,
        grindSize: 'Medium-Coarse',
        totalWaterAmount: 300,
        steps: [
          BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
          BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
          BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
          BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
          BrewStep(waterAmount: 60, waitTime: const Duration(seconds: 45)),
        ],
        note: 'Sweet and Clean cup.',
      ),
      Recipe(
        id: '2',
        name: 'Simple Pour Over',
        beanWeightGrams: 15,
        grindSize: 'Medium',
        totalWaterAmount: 225,
        steps: [
          BrewStep(waterAmount: 30, waitTime: const Duration(seconds: 30)),
          BrewStep(waterAmount: 195, waitTime: const Duration(seconds: 120)),
        ],
        note: 'Daily easy brew.',
      ),
    ];
  }
}
