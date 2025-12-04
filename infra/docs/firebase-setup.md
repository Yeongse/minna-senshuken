# Firebase設定手順

このドキュメントでは、「みんなの選手権」アプリケーションのFirebase Authentication設定手順を説明します。

## 前提条件

- GCPプロジェクトが作成済みであること
- GCPプロジェクトに請求先アカウントが紐付け済みであること

## 1. Firebaseプロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. 既存のGCPプロジェクト（`minna-senshuken`等）を選択
4. Google Analyticsの有効化は任意（無効でも可）
5. 「Firebaseを追加」をクリックして完了

## 2. Firebase Authentication設定

### 2.1 Authenticationの有効化

1. Firebase Consoleで対象プロジェクトを選択
2. 左メニューから「Authentication」を選択
3. 「始める」をクリック

### 2.2 Googleサインインの有効化

1. 「Sign-in method」タブを選択
2. 「Google」をクリック
3. 「有効にする」トグルをオンにする
4. プロジェクトのサポートメールを設定（必須）
5. 「保存」をクリック

## 3. Flutter用設定ファイルの取得

### 3.1 FlutterFire CLIのセットアップ

```bash
# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli

# Firebase CLIをインストール（未インストールの場合）
npm install -g firebase-tools

# Firebase CLIにログイン
firebase login
```

### 3.2 Flutter設定の生成

```bash
# Flutterプロジェクトディレクトリで実行
cd client
flutterfire configure --project=<YOUR_PROJECT_ID>
```

このコマンドにより以下が自動生成されます：
- `lib/firebase_options.dart` - Dart設定ファイル
- `android/app/google-services.json` - Android用設定
- `ios/Runner/GoogleService-Info.plist` - iOS用設定

### 3.3 手動での設定ファイル取得（代替方法）

#### Android用（google-services.json）

1. Firebase Consoleで「プロジェクト設定」を開く
2. 「マイアプリ」セクションでAndroidアプリを選択（または追加）
3. パッケージ名を入力: `com.example.minna_senshuken`
4. 「google-services.json」をダウンロード
5. `client/android/app/` に配置

#### iOS用（GoogleService-Info.plist）

1. Firebase Consoleで「プロジェクト設定」を開く
2. 「マイアプリ」セクションでiOSアプリを選択（または追加）
3. Bundle IDを入力: `com.example.minnaSenshuken`
4. 「GoogleService-Info.plist」をダウンロード
5. Xcodeでプロジェクトを開き、Runnerに追加

## 4. バックエンド用サービスアカウントキー取得

### 4.1 サービスアカウントキーの生成

1. Firebase Consoleで「プロジェクト設定」を開く
2. 「サービスアカウント」タブを選択
3. 「新しい秘密鍵を生成」をクリック
4. JSONキーファイルがダウンロードされる

### 4.2 Secret Managerへの保存（オプション）

ADC（Application Default Credentials）を使用する場合はこの手順は不要です。

```bash
# Secret Managerにサービスアカウントキーを保存
gcloud secrets create firebase-service-account-key \
  --project=<YOUR_PROJECT_ID> \
  --data-file=path/to/downloaded-key.json

# Cloud Runサービスアカウントにアクセス権を付与
gcloud secrets add-iam-policy-binding firebase-service-account-key \
  --project=<YOUR_PROJECT_ID> \
  --role=roles/secretmanager.secretAccessor \
  --member="serviceAccount:cloudrun-api@<YOUR_PROJECT_ID>.iam.gserviceaccount.com"
```

## 5. 必要な環境変数一覧

### バックエンド（Cloud Run）

| 環境変数 | 説明 | 設定方法 |
|---------|------|---------|
| `FIREBASE_PROJECT_ID` | FirebaseプロジェクトID | Terraform outputから自動設定 |
| `GOOGLE_APPLICATION_CREDENTIALS` | サービスアカウントキーのパス | ADC使用時は不要 |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | サービスアカウントキーJSON（直接） | Secret Manager経由（オプション） |

### Firebase Admin SDK初期化コード例

```typescript
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

// ADCを使用する場合（Cloud Run推奨）
if (getApps().length === 0) {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
}

// サービスアカウントキーを使用する場合（ローカル開発など）
// const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
// initializeApp({
//   credential: cert(serviceAccount),
// });

export const auth = getAuth();
```

## トラブルシューティング

### Googleサインインが動作しない

1. Firebase Consoleで「Authentication」>「Settings」を確認
2. 「承認済みドメイン」にCloud RunのURLが含まれているか確認
3. OAuth同意画面が設定されているか確認

### Flutter設定ファイルが見つからない

1. `flutterfire configure` を再実行
2. プロジェクトIDが正しいか確認
3. Firebase CLIにログインしているか確認

### バックエンドでIDトークン検証が失敗する

1. `FIREBASE_PROJECT_ID` が正しく設定されているか確認
2. Cloud Runサービスアカウントに適切な権限があるか確認
3. IDトークンの有効期限が切れていないか確認
