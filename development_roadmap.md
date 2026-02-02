# 開発ロードマップ

## 機能
- [ ] **詳細な焙煎度 (8段階) の実装**
  - **現状**: 3段階（Light, Medium, Dark）の `String` または `Enum`。
  - **目標**: SCAA基準などに基づいた8段階（Light, Cinnamon, Medium, High, City, Full City, French, Italian）への拡張。
  - **実装ステップ**:
    1. `RoastLevel` Enumの拡張。
    2. `Recipe` および `Bean` モデルの更新。
    3. UIの更新（ドロップダウンからスライダー、または専用の選択ダイアログへ変更）。
    4. 既存データのマイグレーション（必要であれば）。

- [x] **データモデルのリファクタリング (TDD)**
  - **目標**: `Recipe.note` を `String` から `String?` (null許容) に変更する。

  - **アプローチ (テスト駆動)**:
    1. 「`note` が `null` の場合のJSON変換」テストケースを追加し、失敗させる（Red）。
    2. モデルを修正してテストをパスさせる（Green）。
    3. UI側の表示ロジック（`isEmpty` チェックなど）を修正する（Refactor）。


## 技術的改善 (Dart習得への道)
1. [x] **Riverpodの導入**
   - 状態管理を `setState` から `Riverpod` へ移行する。
   - 目的: グローバルな状態共有と、ロジックの分離を学ぶ。

2. [x] **Lintの厳格化**
   - `flutter_lints` の設定を強化し、推奨される記述レイアウトを体に叩き込む。

3. [x] **テストの導入**
   - ユニットテスト (`flutter_test`) を書いてみる。


4. [x] **リポジトリのテスト (Mockの活用)**
   - **目標**: `RecipeRepository` の保存・読み込みロジックをテストする。

   - **手法**:
     - `shared_preferences` のモック機能 (`setMockInitialValues`) を使用。
     - 実機に依存せず、CI/CD環境でも実行可能なテストを作成する。
