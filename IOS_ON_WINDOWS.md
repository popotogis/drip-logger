# Windows環境からiOS端末でアプリを使用する方法

残念ながら、**Windows上で直接iOSアプリ（.ipaファイル）をビルドすることはできません**。iOSアプリのビルドにはmacOSとXcodeが必須だからです。

しかし、以下の方法であなたのiPhoneでアプリを動作させることができます。

## 方法1: Webアプリとして実行する (推奨・即効性あり)

FlutterはWebアプリとしても動作します。同じWi-Fiネットワークに接続していれば、Windows上で動かしているアプリにiPhoneのブラウザ(Safari)からアクセスできます。

### 手順

1.  **PCのIPアドレスを確認する**
    *   PowerShellで `ipconfig` を実行し、`IPv4 Address` (例: `192.168.1.5`) をメモします。

2.  **Webサーバーモードで起動する**
    *   VS Codeのターミナルで以下のコマンドを実行します。
    ```bash
    flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
    ```
    *   これにより、ネットワーク内の他の端末からのアクセスが許可されます。

3.  **iPhoneからアクセスする**
    *   iPhoneのSafariを開き、`http://[PCのIPアドレス]:8080` (例: `http://192.168.1.5:8080`) にアクセスします。

4.  **ホーム画面に追加する (PWA化)**
    *   Safariの「共有ボタン」→「ホーム画面に追加」を選択すると、アプリのようなアイコンができ、アドレスバーなしで全画面表示で使えます。

---

## 方法2: クラウドビルドサービスを使う (本格的)

もしネイティブアプリとしてインストールしたい場合は、クラウド上のMac環境でビルドしてくれるCI/CDサービスを利用します。

*   **Codemagic**: Flutterに特化したCI/CDサービス。個人利用の範囲なら無料枠でビルドできる場合があります。
    *   GitHubにコードをプッシュし、Codemagicと連携させることで、クラウド上でiOSビルドを行い、TestFlightなどで配信可能です。
    *   ただし、**Apple Developer Program ($99/年)** への登録と、複雑な証明書設定が必要です。

## 方法3: Macを使ってネイティブビルドする (最も確実)

ご自宅のMacを使って、iPhoneにアプリを直接インストールする手順です。

### 1. プロジェクトをMacに移動する
*   現在の `CoffeeBrewLogger` フォルダを、USBメモリやクラウドストレージ(Google Drive等)経由でMacにコピーします。

### 2. 環境構築 (Mac側)
*   **Xcode**: MacのApp Storeからインストールしてください。
*   **Flutter SDK**: [公式サイト](https://flutter.dev/docs/get-started/install/macos)からダウンロードし、パスを通してください。
*   **CocoaPods**: ターミナルで `sudo gem install cocoapods` を実行してインストールします（iOSのライブラリ管理に必要です）。

### 3. ビルド準備
Macのターミナルで、プロジェクトフォルダに移動して以下を実行します。

```bash
# 依存パッケージの取得
flutter pub get

# iOS用ライブラリのインストール (データ保存機能などで必要)
cd ios
pod install
cd ..
```

### 4. Xcodeでの設定 (署名)
1.  ターミナルで `open ios/Runner.xcworkspace` を実行し、Xcodeを開きます。
2.  左側のナビゲーターで一番上の **Runner** (青いアイコン) をクリックします。
3.  右側の画面で **Signing & Capabilities** タブを開きます。
4.  **Team** のドロップダウンから「Add an Account...」を選択し、あなたのApple IDでログインします。
5.  ログイン後、Teamの選択肢から自分の名前（Personal Team）を選びます。
    *   もし *Bundle Identifier* (現在は `com.example.coffeeBrewLogger`) が重複しているとエラーが出る場合は、末尾に数字や名前を足してユニークにしてください。

### 5. iPhoneへのインストール
1.  iPhoneをUSBケーブルでMacに接続します。
2.  Xcode上部のデバイス選択メニュー（再生ボタンの右）で、接続したiPhoneを選択します。
3.  **再生ボタン (Run)** をクリックします。
4.  ビルドが完了すると、iPhoneにアプリアイコンが表示されます。
    *   **注意**: 初回起動時、「信頼されていない開発者」というエラーが出ることがあります。その場合はiPhoneの「設定」→「一般」→「VPNとデバイス管理」から、自分のApple IDを選択して「信頼」をタップしてください。

## 方法4: Web上に公開して使う (PC接続不要・推奨)

アプリをインターネット上に公開（デプロイ）することで、PCと接続せずにiPhone単体でいつでもどこでもアプリを使えるようになります。
最も簡単な方法である **Netlify Drop** を使う手順を紹介します。

1.  **アプリをビルドする**
    *   VS Codeのターミナルで以下を実行し、公開用のファイルを作成します。
    ```bash
    flutter build web --release
    ```
    *   完了すると、`build` フォルダの中に `web` というフォルダが作成されます（エクスプローラーで `d:\CoffeeBrewLogger\build\web` を確認してください）。

2.  **Netlify Drop にアクセスする**
    *   PCのブラウザで [Netlify Drop](https://app.netlify.com/drop) にアクセスします。
    *   (初めての場合はサインアップが必要です。GitHub/Googleアカウント等で無料登録できます)

3.  **フォルダをアップロードする**
    *   `d:\CoffeeBrewLogger\build\web` フォルダごと、ブラウザの「Drop folder here」等のアップロードエリアにドラッグ＆ドロップします。
    *   数秒〜数分でデプロイが完了し、公開URL（例: `https://random-name-12345.netlify.app`）が発行されます。

4.  **iPhoneで開く**
    *   発行されたURLをiPhoneに送り、Safariで開きます。
    *   「共有ボタン」→「ホーム画面に追加」をタップします。

5.  **完了**
    *   ホーム画面に追加されたアイコンをタップすると、URLバーのないネイティブアプリのような全画面表示で起動します。PCがなくても動作します。

## 結論

PCと繋がずに単体で利用したい場合は、**方法4 (Netlifyへのデプロイ)** が最も手軽で確実です。無料で利用可能です。
