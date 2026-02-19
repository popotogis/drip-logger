import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sembast/sembast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../models/brew_step.dart';
import '../services/database_service.dart';

/// レシピ情報の永続化を担当するリポジトリ
///
/// Sembastを使用して、ローカルDBにデータを保存します。
/// 起動時にSharedPreferenceからのデータ移行も行います。
class RecipeRepository {
  final DatabaseService _databaseService;
  static const String _storeName = 'recipes';
  static const String _keyRecipesSharedPrefs = 'recipes';
  static const String _keyMigrated = 'migrated_recipes_to_sembast';

  final _store = stringMapStoreFactory.store(_storeName);

  RecipeRepository(this._databaseService);

  Future<Database> get _db => _databaseService.database;

  /// 保存されたレシピリストを読み込みます
  ///
  /// [lastUsed] の降順（新しい順）でソートして返却します。
  /// 初回ロード時にデータ移行を試みます。
  Future<List<Recipe>> loadRecipes() async {
    // データ移行の確認と実行
    await migrateFromSharedPreferences();

    final db = await _db;
    final finder = Finder(sortOrders: [SortOrder('lastUsed', false)]);
    final snapshots = await _store.find(db, finder: finder);

    if (snapshots.isEmpty) {
      // 初期データ生成（DBが空の場合のみ）
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyMigrated) == true) {
        // 移行済みフラグがあるのにDBが空 -> ユーザーが全削除したとみなす
        return [];
      } else {
        // 初回起動（フラグなし かつ DB空） -> 初期データを投入
        final defaults = _generateDefaultRecipes();
        // 初期データを永続化（次回以降のために）
        await db.transaction((txn) async {
          for (var recipe in defaults) {
            await _store.record(recipe.id).put(txn, recipe.toJson());
          }
        });
        // 初期化済みとしてフラグを立てる
        await prefs.setBool(_keyMigrated, true);
        return defaults;
      }
    }

    return snapshots.map((snapshot) {
      return Recipe.fromJson(snapshot.value);
    }).toList();
  }

  /// レシピを保存（新規追加・更新）します
  Future<void> saveRecipe(Recipe recipe) async {
    final db = await _db;
    await _store.record(recipe.id).put(db, recipe.toJson());
  }

  /// 特定のレシピを削除します
  Future<void> deleteRecipe(String id) async {
    final db = await _db;
    await _store.record(id).delete(db);
  }

  /// 特定のレシピを取得します
  Future<Recipe?> getRecipe(String id) async {
    final db = await _db;
    final snapshot = await _store.record(id).getSnapshot(db);
    return snapshot != null ? Recipe.fromJson(snapshot.value) : null;
  }

  /// 特定のレシピの使用日時を更新し、リストの先頭に来るようにします
  Future<void> updateLastUsed(String recipeId) async {
    final db = await _db;
    final record = _store.record(recipeId);
    final snapshot = await record.getSnapshot(db);

    if (snapshot != null) {
      final recipe = Recipe.fromJson(snapshot.value);
      final updated = recipe.copyWith(lastUsed: DateTime.now());
      await record.put(db, updated.toJson());
    }
  }

  /// SharedPreferencesからデータを移行します
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_keyMigrated) == true) {
      return;
    }

    final String? jsonString = prefs.getString(_keyRecipesSharedPrefs);
    if (jsonString == null) {
      // 旧データがない場合は何もしない（loadRecipesで初期データを生成させるため、フラグも立てない）
      return;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final recipes = jsonList.map((json) => Recipe.fromJson(json)).toList();

      if (recipes.isNotEmpty) {
        final db = await _db;
        await db.transaction((txn) async {
          for (var recipe in recipes) {
            await _store.record(recipe.id).put(txn, recipe.toJson());
          }
        });
      }

      await prefs.setBool(_keyMigrated, true);
      debugPrint('Migrated ${recipes.length} recipes from SharedPreferences.');
    } catch (e) {
      debugPrint('Error migrating recipes: $e');
      // エラー時もフラグは立てない（再試行可能にするため）
      // ただし、壊れたデータが残り続けると永遠に起動しないリスクもあるが、
      // ここでは安全側に倒してデフォルト生成へフォールバックさせる手もある。
      // 現状は再試行。
    }
  }

  /// 初期データ（サンプル）を生成します
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
        dripper: 'V60',
        grinder: 'Comandante',
        filter: 'Abaca',
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
        dripper: 'Kalita Wave',
        grinder: 'Baratza Encore',
        filter: 'Kalita 155',
      ),
    ];
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return RecipeRepository(dbService);
});
