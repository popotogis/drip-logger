# Drip Logger (Next.js Web App)

理想のコーヒー抽出を追求し、詳細な記録を残すためのドリップログ・ツールです。  
Next.js (App Router) ベースのWebアプリケーションとして再構築されました。

## 主な機能

### 1. 詳細なパラメータ記録
コーヒーを淹れるために必要なあらゆる情報を網羅的に記録できます。

- **コーヒー豆の情報**: 名称、焙煎所、焙煎度、産地、精製方法、品種、焙煎日
- **抽出レシピ**: 豆の分量、湯量、湯温、挽き目、使用器具、テイスティングノート
- **抽出ステップ**: 注湯タイミングと湯量の詳細な計画

### 2. リアルタイム・タイマー連携 (Wake Lock対応)
作成したレシピに従って抽出を実行できます。

- 抽出開始と同時にタイマーが作動し、画面が常時オン（Wake Lock）になります。
- 注湯ステップごとに実績時間を記録。
- 抽出完了後、そのままレシピとして保存したり、Markdownで出力したりできます。

### 3. クラウド同期 (Firebase)
- Google認証によるログイン。
- Firestoreを使用したデータのクラウド保存・同期。
- `legacy_flutter` 版のローカルストレージ (Sembast) からクラウドベースへ移行しました。

### 4. PWA対応
- スマートフォンでもネイティブアプリのようにホーム画面に追加して使用可能です。

---

## 技術構成

- **Frontend**: Next.js 15 (App Router), React 19, TypeScript
- **Styling**: Tailwind CSS v4, shadcn/ui
- **Backend**: Firebase (Authentication, Firestore)
- **Deployment**: GitHub Pages (Static Export)

## 開発環境のセットアップ

```bash
cd next-web
npm install
cp .env.example .env.local
# .env.local にFirebase設定を記述
npm run dev
```

## レガシーコードベース (Flutter)

以前のFlutter版コードベースは `legacy_flutter/` ディレクトリに移動しました。
Flutter版の開発は終了しており、参照用としてこれを行っています。
