# 実装ギャップ分析レポート

## 1. 現状調査

### 1.1 既存資産のマッピング

#### アーキテクチャとディレクトリ構成

モバイルアプリは以下のレイヤー構造で構成されている：

```
mobile/lib/
├── app/                    # アプリケーション層
│   ├── main_shell.dart    # ボトムナビゲーションシェル
│   └── router.dart        # go_routerルーティング設定
├── core/                   # コア層（共通機能）
│   ├── api/               # APIクライアント
│   ├── auth/              # 認証サービス
│   ├── models/            # データモデル
│   ├── services/          # APIサービス
│   └── utils/             # ユーティリティ
└── features/              # 機能層（画面別）
    ├── championship/
    ├── answer/
    └── user/
```

#### 既存の実装状況

**✅ 完全実装済み**:
- `ApiClient`: Dioベースの型安全なHTTPクライアント
- `AuthService`: Firebase Authentication統合
- `AuthInterceptor`: ID Token自動付与
- `ErrorInterceptor`: エラーハンドリングとトークンリフレッシュ
- `ApiException`: 階層的なエラー型システム
- `StorageService`: SharedPreferencesラッパー
- `UploadService`: 画像アップロード（署名付きURL、バリデーション、進捗通知）
- `ChampionshipApi`, `AnswerApi`, `UserApi`: REST APIクライアント
- データモデル: `Championship`, `Answer`, `User`, `Comment`, `Like`
- Riverpod Provider設定: 依存性注入の基盤

**🟡 部分実装（UI骨組みのみ）**:
- 全画面ページコンポーネント（スタブ状態）
  - `HomePage`, `ChampionshipDetailPage`, `ChampionshipCreatePage`
  - `AnswerDetailPage`, `AnswerCreatePage`, `AnswerEditPage`
  - `ProfilePage`, `ProfileEditPage`, `UserDetailPage`
- ルーティング設定（`router.dart`に全ルート定義済み）

**❌ 未実装**:
- 画面ごとの状態管理Provider（Riverpod StateNotifierProvider等）
- UIコンポーネント（一覧表示、フォーム、ローディング、エラー表示）
- バリデーションロジック
- キャッシング機構
- オフライン対応
- サインイン画面とログアウトUI

### 1.2 既存コードの命名規則とパターン

**命名規則**:
- Providerサフィックス: `xxxProvider` (例: `authServiceProvider`, `apiClientProvider`)
- APIクライアント: `XxxApi` (例: `ChampionshipApi`, `AnswerApi`)
- サービス: `XxxService` (例: `AuthService`, `StorageService`)
- 例外: `XxxException` (例: `UnauthorizedException`, `NetworkException`)
- モデル: PascalCase (例: `Championship`, `UserSummary`)

**アーキテクチャパターン**:
- **依存性注入**: Riverpod Providerで全依存関係を管理
- **レイヤー分離**: API → Service → Provider → UI
- **型安全**:
  - `ApiClient.get<T>`でジェネリック型推論
  - `fromJson`ファクトリによるJSON変換
  - sealed class（`ApiException`, `UploadException`）
- **エラーハンドリング**:
  - DioInterceptorでHTTPエラーをApiExceptionに変換
  - エラーコードベースの例外マッピング（`createApiExceptionFromErrorCode`）
- **認証フロー**:
  - AuthInterceptorでリクエストにトークン自動付与
  - ErrorInterceptorでトークン期限切れ時に自動リフレッシュ
  - リフレッシュ失敗時は自動ログアウト

**テストパターン**:
- 各画面に対応するテストファイルが存在（`test/features/**/*_test.dart`）
- 現状はスタブテストのみ

### 1.3 統合ポイント

**バックエンドAPI仕様との整合性**:
- ✅ エンドポイント構造: クライアントAPIサービスはバックエンドルートと一致
- ✅ データモデル: Prismaスキーマとモバイルモデルが整合
- ✅ 認証方式: Firebase ID Token（Bearerトークン）
- ⚠️ API仕様の相違点:
  - バックエンド: `POST /championships` → クライアント実装済み
  - バックエンド: `PUT /championships/:id/force-end`, `PUT /championships/:id/publish-result` → クライアント実装済み
  - 画像アップロード: `POST /uploads/signed-url` → クライアント実装済み

**Firebase統合**:
- `firebase_core`, `firebase_auth`がpubspec.yamlに追加済み
- `AuthService`がFirebaseAuth.instanceをラップ
- サインイン画面は未実装（要件1で実装必要）

**ローカルストレージ**:
- `shared_preferences`パッケージ導入済み
- `StorageService`で型安全なJSON保存・取得が可能
- キャッシュ戦略は未実装

## 2. 要件と既存資産のギャップマッピング

### Requirement 1: 認証機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| サインイン画面表示 | ❌ | **Missing**: サインインUIページとRiverpod状態管理 |
| Firebase UIDとトークンのローカル保存 | ✅ `AuthService.getIdToken()`, `StorageService` | **Constraint**: ログイン状態の永続化ロジック未実装 |
| ログアウト処理 | ✅ `AuthService.signOut()` | **Missing**: ログアウトUIボタンとストレージクリア |
| 自動トークン付与 | ✅ `AuthInterceptor` | 実装済み |
| トークン自動更新 | ✅ `ErrorInterceptor` (TOKEN_EXPIRED時) | 実装済み |
| ログイン状態復元 | ✅ `authStateProvider` (StreamProvider) | **Missing**: 起動時のルーティング制御 |

**ギャップ**:
- サインイン画面（FirebaseUI or カスタムUI）
- プロフィール画面にログアウトボタン
- アプリ起動時の認証状態チェックとルーティング

### Requirement 2: 選手権一覧表示機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 選手権一覧取得 | ✅ `ChampionshipApi.getChampionships()` | 実装済み |
| ステータス別表示 | ✅ APIがステータスフィルタ対応 | **Missing**: UI側のタブ切り替え実装 |
| 一覧表示UI | 🟡 `HomePage`（スタブ） | **Missing**: ListViewウィジェット、選手権カード、StateNotifierProvider |
| ローディング表示 | ❌ | **Missing**: AsyncValue.loading時のCircularProgressIndicator |
| エラー表示 | ❌ | **Missing**: AsyncValue.error時のエラーウィジェット |
| 詳細画面遷移 | ✅ ルーティング定義済み | **Missing**: onTap時のcontext.go()実装 |
| 終了日順ソート | ✅ APIがソート対応 | 実装済み（APIデフォルトはnewest） |
| Pull-to-Refresh | ❌ | **Missing**: RefreshIndicatorウィジェット |

**ギャップ**:
- `championshipListProvider` (StateNotifierProvider<AsyncValue<List<Championship>>>)
- HomePage UI実装（ListView.builder、ChampionshipCardウィジェット）
- Pull-to-Refresh実装

### Requirement 3: 選手権詳細表示機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 選手権詳細取得 | ✅ `ChampionshipApi.getChampionship(id)` | 実装済み |
| 回答一覧取得 | ✅ `AnswerApi.getAnswers(championshipId)` | 実装済み |
| 詳細UI表示 | 🟡 `ChampionshipDetailPage`（スタブ） | **Missing**: 詳細情報表示、回答リスト |
| ローディング表示 | ❌ | **Missing**: AsyncValue対応 |
| エラーハンドリング | ✅ ErrorInterceptor | **Missing**: UI側のエラー表示 |
| 回答詳細遷移 | ✅ ルーティング定義済み | **Missing**: ナビゲーション実装 |
| 回答投稿ボタン（RECRUITING時） | ❌ | **Missing**: ステータス判定とボタン表示 |

**ギャップ**:
- `championshipDetailProvider(id)` (FutureProvider)
- `answerListProvider(championshipId)` (FutureProvider)
- ChampionshipDetailPage UI実装

### Requirement 4: 選手権作成機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 作成API | ✅ `ChampionshipApi.createChampionship()` | 実装済み（durationDays形式） |
| 入力フォームUI | 🟡 `ChampionshipCreatePage`（スタブ） | **Missing**: TextFormField、DatePickerウィジェット |
| バリデーション | ❌ | **Missing**: タイトル50文字、説明500文字、未来日時チェック |
| 作成リクエスト送信 | ✅ API実装済み | **Missing**: StateNotifierでローディング状態管理 |
| 成功時ホーム画面遷移 | ✅ ルーティング | **Missing**: context.go('/')、SnackBar成功メッセージ |
| ローディング状態 | ❌ | **Missing**: ボタン無効化、ローディングインジケーター |
| エラー表示 | ✅ ErrorInterceptor | **Missing**: バリデーションエラー表示 |

**ギャップ**:
- `championshipCreateNotifierProvider` (StateNotifierProvider)
- フォームバリデーションロジック
- UI実装（フォーム、バリデーションエラー表示、ローディングボタン）

### Requirement 5: 回答詳細表示機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 回答詳細取得 | ⚠️ | **Research Needed**: バックエンドに回答詳細エンドポイント（`GET /answers/:id`）が必要か確認 |
| いいね・コメント一覧取得 | ✅ `AnswerApi.getComments()` | **Missing**: いいね一覧API（`GET /answers/:id/likes`）がクライアント未実装 |
| 詳細UI | 🟡 `AnswerDetailPage`（スタブ） | **Missing**: 回答表示、いいね一覧、コメント一覧 |
| いいねボタン | ✅ `AnswerApi.addLike()` | **Missing**: UIボタンと楽観的更新 |
| コメント投稿 | ✅ `AnswerApi.createComment()` | **Missing**: コメント入力欄とリスト更新 |

**ギャップ**:
- いいね一覧取得APIクライアント実装
- `answerDetailProvider(answerId)`, `likeListProvider(answerId)`, `commentListProvider(answerId)`
- UI実装

### Requirement 6: 回答作成機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 回答投稿API | ✅ `AnswerApi.createAnswer()` | 実装済み |
| 画像選択 | ❌ | **Missing**: `image_picker`パッケージ未追加、画像選択UI |
| 画像プレビュー | ❌ | **Missing**: 選択画像表示ウィジェット |
| 画像アップロード | ✅ `UploadService` | 実装済み |
| 入力フォームUI | 🟡 `AnswerCreatePage`（スタブ） | **Missing**: TextFormField、ImagePickerボタン |
| バリデーション | ❌ | **Missing**: テキスト300文字チェック |
| ローディング状態 | ❌ | **Missing**: StateNotifierでローディング管理 |

**ギャップ**:
- `image_picker`、`flutter_image_compress`パッケージ追加
- `answerCreateNotifierProvider`
- UI実装

### Requirement 7: 回答編集機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 回答更新API | ✅ `AnswerApi.updateAnswer()` | 実装済み |
| 既存データ取得 | ⚠️ | **Constraint**: 回答詳細APIから取得する必要がある |
| 編集フォームUI | 🟡 `AnswerEditPage`（スタブ） | **Missing**: フォーム実装 |
| 権限チェック（自分の回答のみ） | ❌ | **Missing**: ユーザーID比較ロジック |
| 画像置換 | ✅ `UploadService` | **Missing**: 既存画像削除フロー（GCS側） |

**ギャップ**:
- `answerEditNotifierProvider`
- 権限チェックロジック
- UI実装

### Requirement 8: プロフィール表示・編集機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| ユーザー情報取得 | ✅ `UserApi` (推測) | **Research Needed**: バックエンドAPIエンドポイント確認 |
| プロフィール表示UI | 🟡 `ProfilePage`（スタブ） | **Missing**: ユーザー情報表示 |
| プロフィール編集UI | 🟡 `ProfileEditPage`（スタブ） | **Missing**: フォーム実装 |
| 更新API | ⚠️ | **Research Needed**: バックエンドに`PATCH /users/me`が必要 |
| アバター画像アップロード | ✅ `UploadService` | 実装済み |
| バリデーション | ❌ | **Missing**: 表示名30文字、自己紹介200文字チェック |

**ギャップ**:
- ユーザーAPI実装確認（`UserApi.getCurrentUser()`, `UserApi.updateProfile()`）
- `profileProvider`, `profileEditNotifierProvider`
- UI実装

### Requirement 9: ユーザー詳細表示機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| ユーザー情報取得 | ⚠️ | **Research Needed**: `GET /users/:id`エンドポイント確認 |
| 投稿一覧取得 | ⚠️ | **Research Needed**: バックエンドAPIで選手権・回答を取得するエンドポイント |
| 詳細UI | 🟡 `UserDetailPage`（スタブ） | **Missing**: UI実装 |

**ギャップ**:
- ユーザーAPIクライアント実装
- `userDetailProvider(userId)`, `userChampionshipsProvider(userId)`, `userAnswersProvider(userId)`
- UI実装

### Requirement 10: エラーハンドリング・状態管理

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| Riverpod状態管理 | ✅ Provider基盤 | **Missing**: 各画面のStateNotifierProvider実装 |
| Dioインターセプター | ✅ `ErrorInterceptor` | 実装済み |
| 401エラー時ログアウト | ✅ `ErrorInterceptor` (signOut呼び出し) | **Missing**: サインイン画面への自動遷移 |
| 400エラー表示 | ✅ エラーメッセージ抽出 | **Missing**: UI側で`ApiException.message`表示 |
| 500エラー表示 | ✅ `ServerException` | **Missing**: UI側で汎用エラーメッセージ表示 |
| ネットワークエラー | ✅ `NetworkException` | **Missing**: UI側で接続エラー表示 |
| AsyncValue使用 | ❌ | **Missing**: 全Provider実装 |

**ギャップ**:
- 401エラー時のナビゲーション処理（GoRouter redirectロジック）
- UI側のエラー表示ウィジェット（ErrorViewコンポーネント）
- 全画面のAsyncValue対応

### Requirement 11: オフライン対応・キャッシング

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| ローカルストレージ | ✅ `StorageService` | 実装済み |
| 認証トークン保存 | ✅ `StorageService.setString()` | **Missing**: 保存ロジック実装 |
| データキャッシング | ❌ | **Missing**: キャッシュ戦略（有効期限、キャッシュキー管理） |
| オフライン表示 | ❌ | **Missing**: キャッシュフォールバック、オフラインインジケーター |
| ネットワーク復帰時の再取得 | ❌ | **Missing**: 接続状態監視とデータリフレッシュ |

**ギャップ**:
- キャッシュ戦略設計（TTL、キャッシュキー）
- `connectivity_plus`パッケージ追加（ネットワーク監視）
- キャッシュ用Provider実装

### Requirement 12: 画像アップロード機能

| 要件 | 既存資産 | ギャップ |
|------|----------|----------|
| 画像選択UI | ❌ | **Missing**: `image_picker`パッケージ未追加 |
| 画像リサイズ・圧縮 | ❌ | **Missing**: `flutter_image_compress`パッケージ未追加 |
| 署名付きURL取得 | ✅ `UploadService._getSignedUrl()` | 実装済み |
| GCSアップロード | ✅ `UploadService._uploadToGcs()` | 実装済み |
| 進捗表示 | ✅ `onProgress`コールバック | **Missing**: UI側のProgressIndicator |
| ファイルタイプ・サイズ検証 | ✅ `UploadService._validateFile()` | 実装済み（JPEG/PNG/GIF、10MB上限） |

**ギャップ**:
- `image_picker`, `flutter_image_compress`パッケージ追加
- 画像選択・圧縮ヘルパー実装
- アップロード進捗UI

## 3. 実装アプローチの選択肢

### Option A: 既存コンポーネントを拡張

**適用範囲**:
- `ChampionshipApi`, `AnswerApi`, `UserApi`にメソッド追加
- 既存Providerファイル（`core/providers.dart`, `auth/auth_provider.dart`）に新規Provider追加
- 既存ページファイルに状態管理とUI実装

**具体的な拡張箇所**:

1. **`core/providers.dart`**:
   - 画面ごとのStateNotifierProviderを追加
   - 例: `championshipListNotifierProvider`, `answerCreateNotifierProvider`

2. **`core/services/user_api.dart`**:
   - `getCurrentUser()`, `updateProfile()`, `getUserById()`メソッド追加

3. **`core/services/answer_api.dart`**:
   - `getLikes(answerId)`メソッド追加

4. **既存ページファイル**:
   - `HomePage` → ConsumerWidgetに変更、AsyncValue対応UI実装
   - `ChampionshipDetailPage` → 同上
   - その他全ページ

**トレードオフ**:
- ✅ 既存の型安全なAPI基盤を活用
- ✅ 統一されたProviderパターンを維持
- ✅ ファイル数増加を抑制
- ❌ `core/providers.dart`が肥大化する可能性
- ❌ 既存ページファイルが複雑化

**互換性評価**:
- ✅ 既存のインターフェース（`ApiClientService`, `AuthServiceInterface`）を尊重
- ✅ テストファイルはそのまま拡張可能

**複雑性・保守性**:
- 🟡 中程度の複雑性: 各画面に100-200行のUI実装が追加される
- 🟡 `providers.dart`の行数が増加（単一責任原則への影響）

### Option B: 新規コンポーネントを作成

**適用範囲**:
- 各機能ごとにProviderファイルを分離
  - `features/championship/providers/championship_list_provider.dart`
  - `features/answer/providers/answer_create_provider.dart`
- 画面ごとに状態管理クラスを分離
  - `features/championship/state/championship_list_state.dart`
  - `features/championship/state/championship_list_notifier.dart`
- 共通UIコンポーネント作成
  - `core/widgets/error_view.dart`
  - `core/widgets/loading_view.dart`
  - `core/widgets/championship_card.dart`

**責任境界**:
- `features/*/providers/`: 画面固有の状態管理Provider
- `features/*/state/`: StateNotifierクラスとState定義
- `features/*/presentation/pages/`: UIのみ（状態管理ロジックなし）
- `features/*/presentation/widgets/`: 画面固有のウィジェット
- `core/widgets/`: 共通ウィジェット

**統合ポイント**:
- 既存の`core/providers.dart`は基盤Providerのみ保持
- 新規Providerは既存Provider（`apiClientProvider`, `authServiceProvider`）に依存
- 既存ページファイルからProviderを参照

**トレードオフ**:
- ✅ 関心の分離が明確
- ✅ テストが書きやすい
- ✅ ファイルサイズが適切
- ❌ ファイル数が大幅に増加（約30-40ファイル追加）
- ❌ 初期実装コストが高い

### Option C: ハイブリッドアプローチ

**組み合わせ戦略**:

**Phase 1 (即座に実装)**:
- **既存拡張**: API メソッド追加（`UserApi`, `AnswerApi`）
- **既存拡張**: `core/providers.dart`に基本的なProviderを追加
- **既存拡張**: 各ページファイルに最小限のUI実装

**Phase 2 (リファクタリング)**:
- **新規作成**: 肥大化した`providers.dart`を分割
- **新規作成**: 共通ウィジェット（`ErrorView`, `LoadingView`, `ChampionshipCard`）を抽出
- **新規作成**: 複雑な画面（`HomePage`, `ChampionshipDetailPage`）の状態管理を分離

**リスク緩和**:
- Phase 1で動作する最小限の実装を完成させる
- Phase 2はオプション（時間があれば実施）
- 段階的に品質を向上

**トレードオフ**:
- ✅ 段階的な実装で早期フィードバック可能
- ✅ リスク分散
- ❌ Phase 1の実装がレガシーになる可能性
- ❌ リファクタリングコストが発生

## 4. 実装の複雑性とリスク評価

### 全体的な見積もり

**工数**: **L (1-2週間)**

**内訳**:
- 認証UI・ルーティング: 2日
- 選手権一覧・詳細表示: 2日
- 選手権作成: 1日
- 回答機能（詳細・作成・編集）: 3日
- プロフィール機能: 2日
- エラーハンドリング・状態管理統合: 1日
- オフライン対応・キャッシング: 2日
- 画像アップロードUI: 1日
- テスト実装: 2日

**リスク**: **Medium**

**リスクの根拠**:
1. **既知のパターン**: Riverpod + Dio + Firebaseは実績あり
2. **新規パッケージ依存**: `image_picker`, `flutter_image_compress`, `connectivity_plus`の追加が必要
   - ⚠️ ネイティブ権限設定（カメラ、ギャラリー）が必要
   - ⚠️ iOSとAndroidで動作確認必須
3. **バックエンドAPI依存**:
   - ⚠️ ユーザーAPI（`GET /users/me`, `PATCH /users/me`, `GET /users/:id`）の存在確認が必要
   - ⚠️ いいね一覧API（`GET /answers/:id/likes`）の存在確認が必要
4. **オフライン実装の複雑性**:
   - ⚠️ キャッシュ戦略の設計が重要（TTL、キャッシュ無効化タイミング）
   - ⚠️ ネットワーク状態監視とリトライロジック
5. **認証フロー**:
   - ⚠️ FirebaseUIの導入 vs カスタムサインイン画面の選択
   - ⚠️ 401エラー時のグローバルナビゲーション処理

### 機能別リスク詳細

| 要件 | 工数 | リスク | 理由 |
|------|------|--------|------|
| Req 1: 認証 | M (3-4日) | Medium | Firebase UI選択、グローバルナビゲーション |
| Req 2: 選手権一覧 | S (1-2日) | Low | 既存パターン、AsyncValue標準対応 |
| Req 3: 選手権詳細 | S (1-2日) | Low | 既存パターン |
| Req 4: 選手権作成 | S (1日) | Low | フォームバリデーション標準実装 |
| Req 5: 回答詳細 | M (2-3日) | Medium | いいね一覧API確認必要 |
| Req 6: 回答作成 | M (2-3日) | Medium | image_picker権限設定 |
| Req 7: 回答編集 | S (1-2日) | Low | 作成機能の応用 |
| Req 8: プロフィール | M (2-3日) | High | ユーザーAPI確認必要 |
| Req 9: ユーザー詳細 | M (2日) | High | ユーザーAPI確認必要 |
| Req 10: エラーハンドリング | S (1日) | Low | ErrorInterceptor拡張 |
| Req 11: オフライン対応 | M (2-3日) | High | キャッシュ戦略設計が複雑 |
| Req 12: 画像アップロード | S (1日) | Medium | UploadService既存、UI実装のみ |

## 5. 設計フェーズへの推奨事項

### 推奨アプローチ

**Option C: ハイブリッドアプローチ**を推奨

**理由**:
1. **Phase 1で早期に動作するMVPを実現**
   - 既存の堅牢なAPI基盤を最大限活用
   - 最小限のファイル追加で全機能を実装
   - 早期フィードバックとイテレーションが可能

2. **Phase 2で品質向上の余地を残す**
   - 共通ウィジェットの抽出
   - Provider分割によるテスタビリティ向上
   - コードレビュー後のリファクタリング

3. **リスク分散**
   - Phase 1失敗時でも段階的にロールバック可能
   - 技術的負債を最小限に抑えつつ早期デリバリー

### 設計フェーズで解決すべき研究項目

以下の項目は設計フェーズで詳細調査が必要：

#### 1. バックエンドAPI仕様確認

**優先度: 高**

調査対象:
- ✅ `GET /users/me`: 現在のユーザー情報取得
- ✅ `PATCH /users/me`: プロフィール更新
- ✅ `GET /users/:id`: ユーザー詳細取得
- ✅ `GET /users/:id/championships`: ユーザーの主催選手権一覧
- ✅ `GET /users/:id/answers`: ユーザーの回答一覧
- ✅ `GET /answers/:id`: 回答詳細取得
- ✅ `GET /answers/:id/likes`: いいね一覧取得

方法:
- バックエンドの`backend/src/routes/`ディレクトリを調査
- 不足しているエンドポイントを特定
- 必要に応じてバックエンド実装を提案

#### 2. 画像アップロードの最適化戦略

**優先度: 中**

調査対象:
- 画像リサイズのベストプラクティス（1024x1024 vs 他の解像度）
- 圧縮率の最適値（品質とファイルサイズのバランス）
- `flutter_image_compress`のプラットフォーム別挙動

参考資料:
- [flutter_image_compress公式ドキュメント](https://pub.dev/packages/flutter_image_compress)
- Googleのモバイル画像最適化ガイドライン

#### 3. オフラインキャッシング戦略

**優先度: 中**

設計項目:
- キャッシュキー設計（例: `championship_list_recruiting`, `championship_detail_${id}`）
- TTL（Time To Live）設定（例: 選手権一覧は5分、詳細は10分）
- キャッシュ無効化タイミング（作成・更新・削除時）
- ストレージ容量制限（最大キャッシュサイズ、LRU削除）

技術選択肢:
- Option 1: `shared_preferences`のみ（シンプル、JSON文字列保存）
- Option 2: `hive`（高速、型安全、複雑なクエリ不要）
- Option 3: `drift (旧moor)`（SQLite、リレーショナルデータ、複雑）

推奨: **Option 1 (shared_preferences)** を Phase 1で使用、必要に応じて Phase 2で`hive`に移行

#### 4. 認証UI実装方法

**優先度: 高**

選択肢:
- **Option A: FirebaseUI for Flutter**
  - ✅ メール/パスワード、Google、Appleサインイン対応
  - ✅ UI実装不要
  - ❌ カスタマイズ制限
  - ❌ パッケージサイズ増加

- **Option B: カスタムサインイン画面**
  - ✅ 完全なデザインコントロール
  - ✅ 軽量
  - ❌ UI実装コスト高

推奨: 設計フェーズでプロダクトオーナーと相談して決定

#### 5. ネットワーク状態監視

**優先度: 低**

技術選択:
- `connectivity_plus`パッケージの導入
- グローバルProviderでネットワーク状態を監視
- オフライン時の自動キャッシュフォールバック

設計タスク:
- ネットワーク復帰時のリフレッシュ戦略
- オフラインインジケーター表示位置（AppBarに常駐 vs SnackBar通知）

### キーとなる設計判断

設計フェーズで決定すべき重要事項:

1. **Provider構成**:
   - 全Providerを`core/providers.dart`に集約 vs 機能別に分散
   - → Phase 1は集約、Phase 2で分散を推奨

2. **画像アップロードフロー**:
   - クライアント側で圧縮してからアップロード vs バックエンドで圧縮
   - → クライアント側圧縮を推奨（帯域削減、UX向上）

3. **エラー表示戦略**:
   - グローバルエラーハンドラ（SnackBar） vs 画面ごとのエラー表示
   - → 画面ごとのErrorViewウィジェットを推奨（コンテキスト明確）

4. **キャッシュ実装タイミング**:
   - Phase 1で実装 vs Phase 2で実装
   - → Phase 1では認証トークンのみ、Phase 2でデータキャッシュを推奨

5. **テスト戦略**:
   - ウィジェットテスト vs 統合テスト
   - → 重要な画面（ホーム、選手権詳細、作成）はウィジェットテスト、全体フローは統合テスト

## 6. まとめ

### 既存資産の強み

- ✅ **堅牢なAPI基盤**: ApiClient、Interceptor、型安全なエラーハンドリング
- ✅ **認証統合**: Firebase AuthとDioの完全な統合
- ✅ **画像アップロード**: 署名付きURL、バリデーション、進捗通知が実装済み
- ✅ **Provider基盤**: Riverpodによる依存性注入が整備済み

### 主要なギャップ

- ❌ **UI実装**: 全画面がスタブ状態
- ❌ **状態管理**: StateNotifierProviderが未実装
- ❌ **バリデーション**: フォームバリデーションロジックなし
- ❌ **キャッシング**: オフライン対応とキャッシュ戦略が未実装
- ⚠️ **バックエンドAPI**: ユーザー関連エンドポイントの確認が必要

### 次のステップ

1. **設計フェーズで実施**:
   - バックエンドAPI仕様の完全調査（優先度: 高）
   - 認証UI実装方法の選択（優先度: 高）
   - オフラインキャッシング戦略の設計（優先度: 中）
   - 画像最適化パラメータの決定（優先度: 中）

2. **実装フェーズ（Phase 1）**:
   - 既存コンポーネント拡張で全機能を実装
   - 最小限のファイル追加で動作するMVPを作成
   - 早期フィードバックを得る

3. **リファクタリングフェーズ（Phase 2）**:
   - 共通ウィジェット抽出
   - Provider分割
   - テストカバレッジ向上

このアプローチにより、既存の優れたアーキテクチャを活かしつつ、段階的に高品質なモバイルアプリを実装できます。
