# 開発ロードマップ

## 機能
- [ ] **高度なデータモデル (Freak Mode)**
  - **目標**: コーヒーマニア（フリーク）の要求に応えつつ、一般ユーザーには負担をかけない柔軟な構造。
  - **Beanモデル拡張**:
    - [x] `process` (精製: Washed, Natural etc.) -> `String?`
    - [x] `variety` (品種: Geisha, Bourbon etc.) -> `String?`
    - [x] `roastDate` (焙煎日) -> `DateTime?`

  - **Recipeモデル拡張**:
    - 抽出環境の柔軟性向上。
    - `dripper` (ドリッパー: V60, Kalita etc.) -> `String?`
    - `grinder` (グラインダー: Comandante, EK43 etc.) -> `String?`
    - `filter` (フィルター: Abaca, Stainless etc.) -> `String?`
    - 将来的には `Map<String, String>` で無限に拡張可能にする構想も持つが、まずは主要な3つを実装。


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
