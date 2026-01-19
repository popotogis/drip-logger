# coffee_brew_logger
コーヒーのハンドドリップのログを記録するためのアプリ

## 何をするアプリか
コーヒーの抽出パラメーター（豆の種類 / 焙煎具合 / 挽き目 / 湯量 / 湯温 / 抽出時間）を記録する

## 具体的な動作
### 1. レシピの設定
パラメーターと詳細な操作(どのタイミングでどのぐらいの湯量を投入するか)を設定する

### 2. レシピの実行
設定したパラメーターで抽出を実行する
- 抽出開始と同時にタイマーが動き出し、レシピに従いコーヒーを入れる
- 実際に抽出を進んだペースはユーザーのボタン入力によってラップタイムとして記録される

### 3. レシピの記録
抽出の完了後に記録を保存する（md形式のファイル）
- パラメータ群
- 抽出の開始時刻と完了時刻
- 設定したパラメータと実際の差分
- 味の感想や次回に向けたフィードバック

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
