import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bean.dart';

/// 豆情報の永続化（保存・読み出し）を担当するリポジトリ
///
/// SharedPreferenceを使用して、JSON形式でローカルにデータを保存します。
class BeanRepository {
  static const String _keyBeans = 'beans';

  /// 保存された豆リストを読み込みます
  ///
  /// データがない場合はデフォルトデータを返します。
  /// [lastUsed] の降順（新しい順）でソートして返却します。
  Future<List<Bean>> loadBeans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyBeans);

    if (jsonString == null) {
      return _generateDefaultBeans();
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final beans = jsonList.map((json) => Bean.fromJson(json)).toList();
      // Sort by lastUsed descending
      beans.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return beans;
    } catch (e) {
      debugPrint('Error loading beans: $e');
      return _generateDefaultBeans();
    }
  }

  /// 豆リストを保存します
  Future<void> saveBeans(List<Bean> beans) async {
    final prefs = await SharedPreferences.getInstance();
    // Sort before saving to be safe, or just trust load to sort? Better to sort on load.
    final String jsonString = jsonEncode(beans.map((b) => b.toJson()).toList());
    await prefs.setString(_keyBeans, jsonString);
  }

  /// 特定の豆の使用日時を更新し、リストの先頭に来るようにします
  Future<void> updateLastUsed(String id) async {
    final beans = await loadBeans();
    final index = beans.indexWhere((b) => b.id == id);
    if (index != -1) {
      final oldBean = beans[index];
      final newBean = Bean(
        id: oldBean.id,
        name: oldBean.name,
        roaster: oldBean.roaster,
        roastLevel: oldBean.roastLevel,
        origin: oldBean.origin,
        lastUsed: DateTime.now(),
      );
      beans[index] = newBean;
      await saveBeans(beans);
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
          origin: 'Ethiopia'),
      Bean(
          id: '2',
          name: 'Colombia Excelso',
          roaster: 'Local Roaster',
          roastLevel: 'Medium'),
    ];
  }
}
