# みんなの選手権 Backend API

お題に対してユーザーが回答を投稿し、主催者が受賞者を選定するWebアプリケーションのバックエンドAPI。

## 技術スタック

- **Runtime**: Node.js 20 LTS
- **Framework**: Hono
- **Database**: MySQL 8.0 (Cloud SQL)
- **ORM**: Prisma
- **認証**: Firebase Authentication
- **ストレージ**: Google Cloud Storage
- **バリデーション**: Zod

## セットアップ

> 📖 **詳細なセットアップ手順**: Firebase/GCS の設定やローカルモックの使い方は [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md) を参照してください。

### 前提条件

- Node.js 20以上
- MySQL 8.0
- Firebase プロジェクト
- Google Cloud プロジェクト（Cloud Storage用）

### インストール

```bash
# 依存関係のインストール
npm install

# Prisma Clientの生成
npm run db:generate
```

### 環境変数の設定

`.env.example`を`.env`にコピーして、値を設定してください。

```bash
cp .env.example .env
```

| 変数名 | 説明 |
|--------|------|
| `DATABASE_URL` | MySQL接続URL |
| `GOOGLE_APPLICATION_CREDENTIALS` | Firebaseサービスアカウントキーのパス |
| `FIREBASE_PROJECT_ID` | FirebaseプロジェクトID |
| `GCS_BUCKET_NAME` | Cloud Storageバケット名 |
| `PORT` | サーバーポート（デフォルト: 8080） |

### データベースのセットアップ

```bash
# マイグレーションの実行（開発環境）
npm run db:migrate

# スキーマのプッシュ（本番環境）
npm run db:push
```

## 開発

```bash
# 開発サーバーの起動（ホットリロード有効）
npm run dev

# テストの実行
npm test

# テストの単発実行
npm run test:run

# ビルド
npm run build

# 本番サーバーの起動
npm start
```

## APIエンドポイント

### 選手権 (Championships)

| メソッド | パス | 説明 | 認証 |
|----------|------|------|------|
| GET | `/championships` | 選手権一覧 | 任意 |
| GET | `/championships/:id` | 選手権詳細 | 任意 |
| POST | `/championships` | 選手権作成 | 必須 |
| PUT | `/championships/:id/force-end` | 強制終了 | 必須（主催者のみ） |
| PUT | `/championships/:id/publish-result` | 結果発表 | 必須（主催者のみ） |

### 回答 (Answers)

| メソッド | パス | 説明 | 認証 |
|----------|------|------|------|
| GET | `/championships/:id/answers` | 回答一覧 | 任意 |
| POST | `/championships/:id/answers` | 回答投稿 | 必須 |
| PUT | `/answers/:id` | 回答編集 | 必須（投稿者のみ） |
| PUT | `/answers/:id/award` | 受賞設定 | 必須（主催者のみ） |
| POST | `/answers/upload-url` | 画像アップロードURL取得 | 必須 |

### いいね・コメント (Interactions)

| メソッド | パス | 説明 | 認証 |
|----------|------|------|------|
| POST | `/answers/:id/like` | いいね追加 | 必須 |
| GET | `/answers/:id/comments` | コメント一覧 | 任意 |
| POST | `/answers/:id/comments` | コメント投稿 | 必須 |

### ユーザー (Users)

| メソッド | パス | 説明 | 認証 |
|----------|------|------|------|
| GET | `/users/:id` | ユーザープロフィール | 任意 |
| PATCH | `/users/me` | プロフィール更新 | 必須 |
| GET | `/users/:id/championships` | ユーザーの選手権一覧 | 任意 |
| GET | `/users/:id/answers` | ユーザーの回答一覧 | 任意 |

### ヘルスチェック

| メソッド | パス | 説明 |
|----------|------|------|
| GET | `/health` | ヘルスチェック |

## プロジェクト構造

```
backend/
├── docs/
│   └── SETUP_GUIDE.md    # 詳細セットアップガイド
├── prisma/
│   └── schema.prisma     # データベーススキーマ
├── src/
│   ├── config/
│   │   └── env.ts        # 環境変数設定
│   ├── lib/
│   │   ├── prisma.ts     # Prismaクライアント
│   │   ├── firebase.ts   # Firebase Admin SDK
│   │   ├── storage.ts    # Cloud Storage
│   │   ├── errors.ts     # エラー定義
│   │   ├── pagination.ts # ページネーション
│   │   └── championship-status.ts # ステータス計算
│   ├── middleware/
│   │   ├── auth.ts       # 認証ミドルウェア
│   │   └── error-handler.ts # エラーハンドラー
│   ├── routes/
│   │   ├── championships.ts # 選手権API
│   │   ├── answers.ts    # 回答API
│   │   ├── interactions.ts # いいね・コメントAPI
│   │   └── users.ts      # ユーザーAPI
│   └── index.ts          # エントリーポイント
├── .env.example          # 環境変数テンプレート
├── package.json
├── tsconfig.json
└── vitest.config.ts
```

## エラーレスポンス形式

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ",
    "details": {}
  }
}
```

### 主なエラーコード

| コード | HTTPステータス | 説明 |
|--------|---------------|------|
| `UNAUTHORIZED` | 401 | 認証が必要 |
| `INVALID_TOKEN` | 401 | トークンが無効 |
| `TOKEN_EXPIRED` | 401 | トークンが期限切れ |
| `FORBIDDEN` | 403 | アクセス権限がない |
| `NOT_OWNER` | 403 | 所有者ではない |
| `CHAMPIONSHIP_NOT_FOUND` | 404 | 選手権が見つからない |
| `ANSWER_NOT_FOUND` | 404 | 回答が見つからない |
| `USER_NOT_FOUND` | 404 | ユーザーが見つからない |
| `VALIDATION_ERROR` | 400 | バリデーションエラー |
| `INVALID_STATUS` | 400 | 不正なステータス |
| `ALREADY_LIKED` | 409 | 既にいいね済み |

## ライセンス

Private
