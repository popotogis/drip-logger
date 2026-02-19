import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリ全体のデータベース接続を管理するサービス
///
/// Sembast DBのシングルトンインスタンスを提供します。
class DatabaseService {
  static const String _dbName = 'drip_logger.db';
  Database? _db;
  final DatabaseFactory _factory;

  DatabaseService({DatabaseFactory? factory})
      : _factory = factory ?? databaseFactoryWeb;

  /// データベースインスタンスを取得します
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    return await _factory.openDatabase(_dbName);
  }

  /// 全てのデータを削除します (Dev Only)
  Future<void> clearAllData() async {
    final db = await database;
    final storeNames = ['recipes', 'beans', 'results'];
    for (var name in storeNames) {
      await stringMapStoreFactory.store(name).delete(db);
    }
  }
}

/// DatabaseServiceのプロバイダー
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
