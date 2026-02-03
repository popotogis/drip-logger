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
      // 初期データ生成（DBが空の場合のみ）
      // ただし、マイグレーション後で空ならそれは「ユーザーが全て削除した」か「初期状態」か区別がつかないが、
      // ここでは簡易的に「真に空なら初期データ」とする。
      // SharedPreferencesからの移行済みフラグがあれば初期データを作らない、という制御も考えられるが、
      // まずはシンプルに「空ならデフォルト」とする（ユーザーが全部消したらまたデフォルトが出る挙動になるが許容範囲か）
      // -> いや、ユーザーが消した後に復活するのはウザいので、
      // "Migrated"フラグがある、かつ空なら「空のリスト」を返すべき。
      // "Migrated"フラグがない（初回起動）かつ空なら「デフォルト」を返す。
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyMigrated) == true) {
        return [];
      } else {
        return _generateDefaultBeans();
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
      // データがない場合も移行済みとしてマーク（次回以降チェックしないため）
      await prefs.setBool(_keyMigrated, true);
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
