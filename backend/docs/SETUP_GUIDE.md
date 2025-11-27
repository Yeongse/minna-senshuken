# セットアップガイド

このドキュメントでは、Firebase Authentication と Google Cloud Storage のセットアップ方法、およびローカル開発時のモック操作について説明します。

## 目次

1. [Firebase Authentication のセットアップ](#firebase-authentication-のセットアップ)
2. [Google Cloud Storage のセットアップ](#google-cloud-storage-のセットアップ)
3. [ローカル開発時のモック操作](#ローカル開発時のモック操作)

---

## Firebase Authentication のセットアップ

### 1. Firebase プロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（例: `minna-senshuken`）
4. Google Analytics の設定（任意）
5. 「プロジェクトを作成」をクリック

### 2. Authentication の有効化

1. Firebase Console で作成したプロジェクトを開く
2. 左メニューから「Authentication」を選択
3. 「始める」をクリック
4. 「Sign-in method」タブで使用する認証方法を有効化
   - 推奨: Google、メール/パスワード

### 3. サービスアカウントキーの取得

バックエンドで Firebase Admin SDK を使用するため、サービスアカウントキーが必要です。

1. Firebase Console で「プロジェクトの設定」（歯車アイコン）を開く
2. 「サービスアカウント」タブを選択
3. 「新しい秘密鍵の生成」をクリック
4. JSONファイルがダウンロードされる
5. ダウンロードしたファイルを `backend/firebase-service-account.json` として保存

```bash
# ファイルを配置
mv ~/Downloads/your-project-firebase-adminsdk-xxxxx.json ./firebase-service-account.json
```

### 4. 環境変数の設定

`.env` ファイルに以下を設定:

```env
GOOGLE_APPLICATION_CREDENTIALS="./firebase-service-account.json"
FIREBASE_PROJECT_ID="your-project-id"
```

> ⚠️ **注意**: `firebase-service-account.json` は機密情報です。絶対に Git にコミットしないでください（`.gitignore` に含まれています）。

---

## Google Cloud Storage のセットアップ

### 1. GCP プロジェクトの確認

Firebase プロジェクトを作成すると、対応する GCP プロジェクトが自動的に作成されます。

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. Firebase プロジェクトと同じ名前のプロジェクトを選択

### 2. Cloud Storage バケットの作成

1. GCP Console で「Cloud Storage」>「バケット」を開く
2. 「バケットを作成」をクリック
3. 設定:
   - **名前**: グローバルに一意な名前（例: `minna-senshuken-uploads`）
   - **ロケーション**: `asia-northeast1`（東京）推奨
   - **ストレージクラス**: Standard
   - **アクセス制御**: 「均一」を選択
4. 「作成」をクリック

### 3. バケットの公開設定（画像を公開する場合）

アップロードされた画像を公開URLでアクセス可能にする場合:

1. バケットを選択
2. 「権限」タブを開く
3. 「アクセス権を付与」をクリック
4. 設定:
   - **新しいプリンシパル**: `allUsers`
   - **ロール**: `Storage オブジェクト閲覧者`
5. 「保存」をクリック

### 4. CORS 設定

ブラウザから直接アップロードする場合、CORS 設定が必要です。

`cors.json` ファイルを作成:

```json
[
  {
    "origin": ["http://localhost:3000", "https://your-domain.com"],
    "method": ["GET", "PUT", "POST"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

gsutil コマンドで適用:

```bash
gsutil cors set cors.json gs://your-bucket-name
```

### 5. 環境変数の設定

`.env` ファイルに以下を追加:

```env
GCS_BUCKET_NAME="your-bucket-name"
```

### 6. サービスアカウントの権限確認

Firebase のサービスアカウントに Cloud Storage の権限があることを確認:

1. GCP Console で「IAM と管理」>「IAM」を開く
2. Firebase のサービスアカウント（`firebase-adminsdk-xxxxx@...`）を探す
3. 「Storage オブジェクト管理者」ロールがあることを確認
4. なければ「編集」から追加

---

## ローカル開発時のモック操作

### テスト時のモック

テストファイルでは、外部サービスを自動的にモックしています。

#### Prisma（データベース）のモック

```typescript
import { vi } from 'vitest';

vi.mock('../lib/prisma', () => ({
  prisma: {
    championship: {
      findUnique: vi.fn(),
      findMany: vi.fn(),
      count: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    // 他のモデルも同様
  },
}));

// 使用例
import { prisma } from '../lib/prisma';

vi.mocked(prisma.championship.findMany).mockResolvedValue([
  { id: 'test-id', title: 'Test Championship', /* ... */ }
]);
```

#### Firebase 認証のモック

```typescript
vi.mock('../lib/firebase', () => ({
  getAuth: vi.fn(() => ({
    verifyIdToken: vi.fn(),
  })),
  initializeFirebase: vi.fn(),
}));
```

#### 認証ミドルウェアのモック

テストでは `X-Mock-User` ヘッダーでユーザーを指定できます:

```typescript
vi.mock('../middleware/auth', () => ({
  requireAuth: vi.fn(() => async (c: any, next: any) => {
    const mockUser = c.req.header('X-Mock-User');
    if (mockUser) {
      c.set('user', JSON.parse(mockUser));
    }
    await next();
  }),
}));

// リクエスト時
const res = await app.request('/championships', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Mock-User': JSON.stringify({
      id: 'user-123',
      firebaseUid: 'firebase-uid-123',
      displayName: 'Test User',
    }),
  },
  body: JSON.stringify({ /* ... */ }),
});
```

#### Cloud Storage のモック

```typescript
vi.mock('../lib/storage', () => ({
  generateUploadUrl: vi.fn(),
}));

// 使用例
import { generateUploadUrl } from '../lib/storage';

vi.mocked(generateUploadUrl).mockResolvedValue({
  uploadUrl: 'https://signed-url.example.com',
  publicUrl: 'https://storage.googleapis.com/bucket/path/image.png',
  expiresAt: new Date(Date.now() + 15 * 60 * 1000),
});
```

### ローカル開発時の実サービス接続

#### Firebase エミュレータの使用（オプション）

Firebase Local Emulator Suite を使用すると、実際の Firebase プロジェクトに接続せずに開発できます。

```bash
# Firebase CLI のインストール
npm install -g firebase-tools

# エミュレータの初期化
firebase init emulators

# エミュレータの起動
firebase emulators:start
```

環境変数でエミュレータに接続:

```env
FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"
```

#### ローカル MySQL の起動

Docker を使用する場合:

```bash
docker run --name mysql-local \
  -e MYSQL_ROOT_PASSWORD=password \
  -e MYSQL_DATABASE=minna_senshuken \
  -e MYSQL_USER=user \
  -e MYSQL_PASSWORD=password \
  -p 3306:3306 \
  -d mysql:8.0
```

### 開発サーバーの起動

```bash
# 依存関係のインストール
npm install

# Prisma Client の生成
npm run db:generate

# マイグレーションの実行
npm run db:migrate

# 開発サーバーの起動
npm run dev
```

---

## トラブルシューティング

### Firebase 認証エラー

```
Error: Failed to determine project ID
```

→ `GOOGLE_APPLICATION_CREDENTIALS` と `FIREBASE_PROJECT_ID` が正しく設定されているか確認

### Cloud Storage 権限エラー

```
Error: Caller does not have storage.objects.create access
```

→ サービスアカウントに「Storage オブジェクト管理者」ロールを付与

### データベース接続エラー

```
Error: Can't reach database server
```

→ MySQL が起動しているか、`DATABASE_URL` が正しいか確認

---

## 参考リンク

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Admin SDK ドキュメント](https://firebase.google.com/docs/admin/setup)
- [Google Cloud Storage ドキュメント](https://cloud.google.com/storage/docs)
- [Prisma ドキュメント](https://www.prisma.io/docs)
