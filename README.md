# みんなの選手権

> みんなで楽しむ大喜利プラットフォーム

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 📖 概要

「みんなの選手権」は、Twitter上で人気の坊主(@bozu_108)さんが開催している「選手権」企画を、誰でも主催・参加できるプラットフォームとして提供するアプリケーションです。

- 🎯 **お題を投稿**: 「〜あるある選手権」などのお題を作成
- 💡 **回答を投稿**: テキスト + 画像で自由に回答
- ❤️ **評価する**: いいね・コメントで盛り上がる
- 🏆 **受賞作品を選定**: 主催者が最優秀賞・入賞・特別賞を決定

## 🏗️ アーキテクチャ

このリポジトリはモノレポ構成で、モバイルアプリとバックエンドAPIを一元管理します。

```
minna-senshuken/
├── mobile/          # Flutter モバイルアプリ
├── api/             # Hono API (Cloud Run)
├── docs/            # ドキュメント
└── infrastructure/  # インフラ設定（Terraform等）
```

## 🛠️ 技術スタック

### モバイル（Flutter）
- **フレームワーク**: Flutter 3.x
- **状態管理**: Riverpod
- **ルーティング**: go_router
- **認証**: Firebase Authentication
- **HTTP クライアント**: dio
- **画像処理**: image_picker, flutter_image_compress

### バックエンド（Hono API）
- **フレームワーク**: Hono
- **ランタイム**: Node.js 20
- **ホスティング**: Google Cloud Run
- **データベース**: Cloud SQL (MySQL 8.0)
- **ORM**: Prisma
- **ストレージ**: Google Cloud Storage
- **認証**: Firebase Admin SDK

### インフラ
- **クラウド**: Google Cloud Platform
- **IaC**: Terraform
- **CI/CD**: GitHub Actions

## 📁 ディレクトリ構成

```
minna-senshuken/
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── features/          # 機能別モジュール
│   │   │   ├── championship/  # 選手権機能
│   │   │   ├── answer/        # 回答機能
│   │   │   ├── user/          # ユーザー機能
│   │   │   └── auth/          # 認証機能
│   │   ├── core/              # 共通機能
│   │   │   ├── api/           # API クライアント
│   │   │   ├── utils/         # ユーティリティ
│   │   │   └── widgets/       # 共通ウィジェット
│   │   └── app/               # アプリ設定
│   ├── test/
│   ├── pubspec.yaml
│   └── README.md
│
├── api/
│   ├── src/
│   │   ├── index.ts           # エントリーポイント
│   │   ├── routes/            # ルーティング
│   │   │   ├── championships.ts
│   │   │   ├── answers.ts
│   │   │   └── users.ts
│   │   ├── services/          # ビジネスロジック
│   │   ├── repositories/      # データアクセス層
│   │   ├── middleware/        # ミドルウェア
│   │   └── utils/             # ユーティリティ
│   ├── prisma/
│   │   └── schema.prisma      # データベーススキーマ
│   ├── tests/
│   ├── package.json
│   └── README.md
│
├── docs/
│   ├── requirements.md        # 要件定義書
│   ├── design-guide.md        # デザインガイドライン
│   ├── api-spec.md            # API仕様書
│   ├── database-schema.md     # データベース設計書
│   └── deployment.md          # デプロイ手順
│
├── infrastructure/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── modules/
│   └── README.md
│
├── .github/
│   └── workflows/
│       ├── mobile-ci.yml      # モバイルCI
│       ├── api-ci.yml         # API CI
│       └── deploy.yml         # デプロイワークフロー
│
├── README.md                  # このファイル
├── LICENSE
└── .gitignore
```

## 🚀 セットアップ

### 前提条件

- **Flutter**: 3.24.0 以上
- **Node.js**: 20.x 以上
- **Docker**: 20.10 以上（ローカル開発用）
- **Google Cloud SDK**: 最新版
- **Firebase CLI**: 最新版

### 環境構築

#### 1. リポジトリのクローン

```bash
git clone https://github.com/your-org/minna-senshuken.git
cd minna-senshuken
```

#### 2. モバイルアプリのセットアップ

```bash
cd mobile

# 依存関係のインストール
flutter pub get

# コード生成（Riverpod, JSON等）
flutter pub run build_runner build --delete-conflicting-outputs

# Firebase設定ファイルの配置
# firebase_options.dart を lib/ に配置

# 実行
flutter run
```

#### 3. バックエンドAPIのセットアップ

```bash
cd api

# 依存関係のインストール
npm install

# 環境変数の設定
cp .env.example .env
# .env ファイルを編集

# データベースのセットアップ（ローカル開発）
docker-compose up -d

# Prismaマイグレーション
npx prisma migrate dev

# 開発サーバー起動
npm run dev
```

### 環境変数

#### モバイル（Firebase設定）
```bash
# Firebase設定は firebase_options.dart に自動生成
# FlutterFire CLI を使用:
flutterfire configure
```

#### API（.env）
```bash
# データベース
DATABASE_URL=mysql://user:password@localhost:3306/minna_senshuken

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Google Cloud Storage
GCS_BUCKET_NAME=minna-senshuken-images
GCS_PROJECT_ID=your-project-id

# その他
NODE_ENV=development
PORT=8080
```

## 🧪 テスト

### モバイル

```bash
cd mobile

# 単体テスト
flutter test

# ウィジェットテスト
flutter test test/widget_test.dart

# 統合テスト
flutter test integration_test/
```

### API

```bash
cd api

# 単体テスト
npm test

# カバレッジ付き
npm run test:coverage

# E2Eテスト
npm run test:e2e
```

## 📦 ビルド

### モバイル

```bash
cd mobile

# Android APK
flutter build apk --release

# iOS IPA（Mac のみ）
flutter build ipa --release

# Android App Bundle
flutter build appbundle --release
```

### API

```bash
cd api

# ビルド
npm run build

# Docker イメージ
docker build -t minna-senshuken-api:latest .
```

## 🚢 デプロイ

### API（Cloud Run）

```bash
cd api

# Cloud Run へデプロイ
gcloud run deploy minna-senshuken-api \
  --source . \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated
```

### モバイル

- **Android**: Google Play Console へアップロード
- **iOS**: App Store Connect へアップロード

詳細は [docs/deployment.md](docs/deployment.md) を参照してください。

## 📚 ドキュメント

- [要件定義書](docs/requirements.md)
- [デザインガイドライン](docs/design-guide.md)
- [API仕様書](docs/api-spec.md)
- [データベース設計書](docs/database-schema.md)
- [デプロイ手順](docs/deployment.md)

## 🤝 開発フロー

### ブランチ戦略

```
main           # 本番環境
├── develop    # 開発環境
    ├── feature/xxx  # 機能開発
    ├── fix/xxx      # バグ修正
    └── refactor/xxx # リファクタリング
```

### コミットメッセージ規約

```
feat: 新機能
fix: バグ修正
docs: ドキュメント更新
style: コードスタイル修正
refactor: リファクタリング
test: テスト追加・修正
chore: ビルド・設定変更
```

例:
```bash
feat(mobile): 選手権一覧画面の実装
fix(api): いいね重複登録の不具合修正
docs: API仕様書の更新
```

## 🔧 開発ツール

### 推奨エディタ

- **VSCode** (推奨拡張機能)
  - Flutter
  - Dart
  - ESLint
  - Prettier
  - Prisma

- **Android Studio** (モバイル開発)

### コードフォーマット

```bash
# Flutter
cd mobile
flutter format .

# API
cd api
npm run format
```

### リント

```bash
# Flutter
cd mobile
flutter analyze

# API
cd api
npm run lint
```

## 📊 プロジェクト管理

- **課題管理**: GitHub Issues
- **プロジェクトボード**: GitHub Projects
- **コードレビュー**: GitHub Pull Requests

## 🐛 バグ報告・機能リクエスト

バグを発見した場合や新機能のアイデアがある場合は、[GitHub Issues](https://github.com/your-org/minna-senshuken/issues) からお願いします。

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 👥 コントリビューター

このプロジェクトに貢献してくださった方々に感謝します。

## 📞 お問い合わせ

- **メール**: support@minna-senshuken.app
- **Twitter**: [@minna_senshuken](https://twitter.com/minna_senshuken)

## 🗺️ ロードマップ

### Phase 1: MVP（最小viable製品）✅ 進行中
- [ ] ユーザー認証・プロフィール管理
- [ ] 選手権のCRUD
- [ ] 回答のCRUD
- [ ] いいね・コメント機能
- [ ] 受賞設定・結果発表

### Phase 2: 機能拡張
- [ ] 選手権の検索・フィルタリング強化
- [ ] 通知機能
- [ ] SNSシェア機能
- [ ] ランキング機能

### Phase 3: 成長期
- [ ] タグ・カテゴリ機能
- [ ] ユーザーフォロー機能
- [ ] プッシュ通知
- [ ] アプリ内課金（プレミアム機能）

---

**Made with ❤️ by the Minna Senshuken Team**