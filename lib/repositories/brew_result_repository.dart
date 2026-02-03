import 'package:sembast/sembast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brew_result.dart';
import '../services/database_service.dart';

/// ドリップ実績（BrewResult）の永続化を担当するリポジトリ
///
/// Sembast (Simple Embedded Application Store) を使用して、
/// WebのIndexedDB上にデータを保存します。
class BrewResultRepository {
  final DatabaseService _databaseService;
  static const String _storeName = 'results';

  // String型のキーを持つストアを作成
  final _store = stringMapStoreFactory.store(_storeName);

  BrewResultRepository(this._databaseService);

  /// データベースインスタンスを取得します
  Future<Database> get _db => _databaseService.database;

  /// 実績データを保存（追加・上書き）します
  ///
  /// [result.id] をキーとして保存します。
  Future<void> addResult(BrewResult result) async {
    final db = await _db;
    await _store.record(result.id).put(db, result.toJson());
  }

  /// 全ての実績データを取得します
  ///
  /// [brewedAt] の降順（新しい順）で並び替えて返します。
  Future<List<BrewResult>> getAllResults() async {
    final db = await _db;
    final finder = Finder(sortOrders: [SortOrder('brewedAt', false)]);
    final snapshots = await _store.find(db, finder: finder);

    return snapshots.map((snapshot) {
      return BrewResult.fromJson(snapshot.value);
    }).toList();
  }

  /// 特定の実績データを削除します
  Future<void> deleteResult(String id) async {
    final db = await _db;
    await _store.record(id).delete(db);
  }
}

/// BrewResultRepositoryのプロバイダー
final brewResultRepositoryProvider = Provider<BrewResultRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BrewResultRepository(dbService);
});
