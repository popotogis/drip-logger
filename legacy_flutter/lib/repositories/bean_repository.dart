import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sembast/sembast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bean.dart';
import '../services/database_service.dart';

/// 豆情報の永続化（保存・読み出し）を担当するリポジトリ
///
/// Sembastを使用して、ローカルDBにデータを保存します。
/// 起動時にSharedPreferencesからのデータ移行も行います。
class BeanRepository {
  final DatabaseService _databaseService;
  static const String _storeName = 'beans';
  static const String _keyBeansSharedPrefs = 'beans';
  static const String _keyMigrated = 'migrated_beans_to_sembast';

  final _store = stringMapStoreFactory.store(_storeName);

  BeanRepository(this._databaseService);

  Future<Database> get _db => _databaseService.database;

  /// 保存された豆リストを読み込みます
  ///
  /// [lastUsed] の降順（新しい順）でソートして返却します。
  /// 初回ロード時にデータ移行を試みます。
  Future<List<Bean>> loadBeans() async {
    // データ移行の確認と実行
    await migrateFromSharedPreferences();

    final db = await _db;
    final finder = Finder(sortOrders: [SortOrder('lastUsed', false)]);
    final snapshots = await _store.find(db, finder: finder);

    if (snapshots.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyMigrated) == true) {
        return [];
      } else {
        // 初回起動（フラグなし かつ DB空） -> 初期データを投入
        final defaults = _generateDefaultBeans();
        // 初期データを永続化
        await db.transaction((txn) async {
          for (var bean in defaults) {
            await _store.record(bean.id).put(txn, bean.toJson());
          }
        });
        // 初期化済みとしてフラグを立てる
        await prefs.setBool(_keyMigrated, true);
        return defaults;
      }
    }

    return snapshots.map((snapshot) {
      return Bean.fromJson(snapshot.value);
    }).toList();
  }

  /// 豆を保存（新規追加・更新）します
  Future<void> saveBean(Bean bean) async {
    final db = await _db;
    await _store.record(bean.id).put(db, bean.toJson());
  }

  /// 特定の豆を削除します
  Future<void> deleteBean(String id) async {
    final db = await _db;
    await _store.record(id).delete(db);
  }

  /// 特定の豆の使用日時を更新し、保存します
  Future<void> updateLastUsed(String id) async {
    final db = await _db;
    final record = _store.record(id);
    final snapshot = await record.getSnapshot(db);

    if (snapshot != null) {
      final bean = Bean.fromJson(snapshot.value);
      final updatedBean = bean.copyWith(lastUsed: DateTime.now());
      await record.put(db, updatedBean.toJson());
    }
  }

  /// SharedPreferencesからデータを移行します
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // 既に移行済みなら何もしない
    if (prefs.getBool(_keyMigrated) == true) {
      return;
    }

    final String? jsonString = prefs.getString(_keyBeansSharedPrefs);
    if (jsonString == null) {
      // データがない場合も移行済みとしてマークしない（loadBeansで初期データを入れるため）
      return;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final beans = jsonList.map((json) => Bean.fromJson(json)).toList();

      if (beans.isNotEmpty) {
        final db = await _db;
        // トランザクションで一括保存
        await db.transaction((txn) async {
          for (var bean in beans) {
            await _store.record(bean.id).put(txn, bean.toJson());
          }
        });
      }

      // 移行完了フラグをセット
      await prefs.setBool(_keyMigrated, true);
      // 旧データは削除しても良いが、安全のため残す選択もアリ。今回は残す。
      debugPrint('Migrated ${beans.length} beans from SharedPreferences.');
    } catch (e) {
      debugPrint('Error migrating beans: $e');
      // エラー時はフラグを立てない（次回再試行）
    }
  }

  /// 初期データ（サンプル）を生成します
  List<Bean> _generateDefaultBeans() {
    return [
      Bean(
          id: '1',
          name: 'Ethiopia Yirgacheffe',
          roaster: 'The Barn',
          roastLevel: 'Light',
          origin: 'Ethiopia',
          process: 'Washed',
          variety: 'Heirloom',
          roastDate: DateTime.now().subtract(const Duration(days: 7))),
      Bean(
          id: '2',
          name: 'Colombia Excelso',
          roaster: 'Local Roaster',
          roastLevel: 'Medium',
          process: 'Washed',
          variety: 'Caturra',
          roastDate: DateTime.now().subtract(const Duration(days: 14))),
    ];
  }
}

final beanRepositoryProvider = Provider<BeanRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BeanRepository(dbService);
});
