import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';

class RecipeSharer {
  /// 共有用リンクのプレフィックス (これを見てアプリ内データか判断する)
  static const _prefix = 'driplogger://recipe/';

  /// レシピを共有用コードに変換 (Export)
  static String encode(Recipe recipe) {
    try {
      // 1. JSON Mapに変換
      final jsonMap = recipe.toJson();
      // 2. 文字列化
      final jsonStr = jsonEncode(jsonMap);
      // 3. UTF-8バイト列化
      final bytes = utf8.encode(jsonStr);
      // 4. Base64 (URL Safe) エンコード
      final base64Str = base64Url.encode(bytes);

      return '$_prefix$base64Str';
    } catch (e) {
      debugPrint('Encode error: $e');
      return '';
    }
  }

  /// 共有用コードからレシピを復元 (Import)
  /// 失敗すると null を返す
  static Recipe? decode(String code) {
    if (!code.startsWith(_prefix)) return null;

    try {
      // 1. プレフィックス除去
      final base64Str = code.substring(_prefix.length);
      // 2. Base64 デコード (URL safe)
      final bytes = base64Url.decode(base64Str);
      // 3. UTF-8 文字列化
      final jsonStr = utf8.decode(bytes);
      // 4. JSON Map化
      final jsonMap = jsonDecode(jsonStr);
      // 5. Recipeオブジェクト化
      return Recipe.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Decode error: $e');
      return null;
    }
  }
}
