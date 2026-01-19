# Flutter SDK インストール手順 (Windows)

iOS/Androidアプリ開発に必要な「Flutter SDK」をWindowsに導入する手順です。

## 1. SDKのダウンロード

1.  Flutter公式サイトのダウンロードページにアクセスします。
    *   URL: [https://docs.flutter.dev/get-started/install/windows/mobile?tab=download](https://docs.flutter.dev/get-started/install/windows/mobile?tab=download)
2.  **`flutter_windows_3.x.x-stable.zip`** という青いボタンをクリックしてダウンロードします。

## 2. 解凍と配置

1.  ダウンロードしたzipファイルを解凍します。
2.  中にある `flutter` というフォルダを、適切な場所に配置します。
    *   **推奨**: `C:\src\flutter`
    *   **注意**: `C:\Program Files` のような権限が必要な場所は避けてください。

## 3. パス (Path) の設定

コマンドプロンプトやPowerShellで `flutter` コマンドを使えるようにします。

1.  Windowsの検索バーで「環境変数」と検索し、「システム環境変数の編集」を開きます。
2.  「環境変数」ボタンをクリックします。
3.  「ユーザー環境変数」のリストにある **`Path`** を選択して「編集」をクリックします。
4.  「新規」をクリックし、Flutterの `bin` フォルダのパスを入力します。
    *   例: `C:\src\flutter\bin`
5.  全て「OK」で閉じます。

## 4. 確認

1.  新しいPowerShellウィンドウを開きます。
2.  以下のコマンドを実行します。
    ```powershell
    flutter doctor
    ```
3.  これが実行できればインストール成功です！
    *   いくつかの項目に `[X]` や `[!]` がつくかもしれませんが、まずはコマンドが通ればOKです。

---

## 次のステップ：プロジェクトの反映

インストールが完了したら、このディレクトリ (`d:\CoffeeBrewLogger`) で以下のコマンドを実行してください。
これにより、iOS/Android開発に必要なファイル群が自動生成されます。

```powershell
flutter create .
```
