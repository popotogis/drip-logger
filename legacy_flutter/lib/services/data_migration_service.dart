import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/recipe_repository.dart';
import '../repositories/firestore_recipe_repository.dart';

final dataMigrationServiceProvider = Provider<DataMigrationService>((ref) {
  return DataMigrationService(ref);
});

class DataMigrationService {
  final Ref _ref;
  static const String _keyMigrationComplete = 'migration_to_firestore_complete';

  DataMigrationService(this._ref);

  /// local DB to Firestore
  Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_keyMigrationComplete) == true) {
      return;
    }

    try {
      final localRepo = _ref.read(recipeRepositoryProvider);
      final firestoreRepo = _ref.read(firestoreRecipeRepositoryProvider);

      final localRecipes = await localRepo.loadRecipes();

      if (localRecipes.isEmpty) {
        await prefs.setBool(_keyMigrationComplete, true);
        return;
      }

      for (final recipe in localRecipes) {
        await firestoreRepo.saveRecipe(recipe);
      }

      await prefs.setBool(_keyMigrationComplete, true);
      print('Migration completed: ${localRecipes.length} recipes copied');
    } catch (e) {
      print('Migration failed: ${e}');
    }
  }
}
