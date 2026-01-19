import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bean.dart';

class BeanRepository {
  static const String _keyBeans = 'beans';

  Future<List<Bean>> loadBeans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyBeans);

    if (jsonString == null) {
      return _generateDefaultBeans();
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Bean.fromJson(json)).toList();
    } catch (e) {
      print('Error loading beans: $e');
      return _generateDefaultBeans();
    }
  }

  Future<void> saveBeans(List<Bean> beans) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(beans.map((b) => b.toJson()).toList());
    await prefs.setString(_keyBeans, jsonString);
  }

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
