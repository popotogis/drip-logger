import 'package:flutter/material.dart';
import 'screens/recipe_list_screen.dart';

/// アプリの開始地点 (Entry Point)
void main() {
  // CoffeeLoggerApp という「ウィジェット（部品）」を起動します
  runApp(const CoffeeLoggerApp());
}

/// アプリ全体を表すクラス
///
/// テーマ設定やルーティングを一元管理します。
/// [StatelessWidget] は「動的に変化する状態を持たない」部品です。
class CoffeeLoggerApp extends StatelessWidget {
  const CoffeeLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp は、アプリ全体のデザインやナビゲーションを管理する大枠です
    return MaterialApp(
      title: 'Drip-Logger',

      // アプリ全体のテーマ設定（色やフォントなど）
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          background: Colors.grey[100]!,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
        ),
      ),

      // アプリ起動時に最初に表示される画面
      home: const RecipeListScreen(),
    );
  }
}
