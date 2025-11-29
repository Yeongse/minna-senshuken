# Research & Design Decisions

---
**Purpose**: モバイルクライアント実装におけるディスカバリー調査結果と設計判断の根拠を記録

**Usage**:
- ディスカバリーフェーズで実施した調査活動と結果をログ化
- 設計判断のトレードオフを詳細に記録
- 将来の監査や再利用のための参考資料を提供
---

## Summary
- **Feature**: `mobile-client`
- **Discovery Scope**: Extension（既存システムの拡張）
- **Key Findings**:
  - バックエンドAPIは要件を満たす全エンドポイントを提供済み（ユーザーAPI、いいね一覧APIを含む）
  - 既存のRiverpod + Dio + Firebase Authインフラは堅牢で、拡張可能
  - 画像処理に必要な`image_picker`, `flutter_image_compress`パッケージの追加が必要
  - Phase 1ではshared_preferencesによるキャッシング、Phase 2でHiveへの移行を検討

## Research Log

### バックエンドAPI仕様の確認

- **Context**: ギャップ分析でユーザー関連API、いいね一覧API、回答詳細APIの存在確認が必要と特定された
- **Sources Consulted**:
  - `/backend/src/routes/users.ts`
  - `/backend/src/routes/answers.ts`
  - `/backend/src/routes/interactions.ts`
- **Findings**:
  - ✅ `GET /users/:id`: ユーザー詳細取得（displayName, avatarUrl, bio, twitterUrl, createdAt）
  - ✅ `PATCH /users/me`: プロフィール更新（認証必須、displayName/bio/avatarUrl/twitterUrlをオプションで受け取る）
  - ✅ `GET /users/:id/championships`: ユーザーの主催選手権一覧（ページネーション対応）
  - ✅ `GET /users/:id/answers`: ユーザーの回答一覧（ページネーション対応）
  - ✅ `GET /answers/:id/comments`: コメント一覧取得（ページネーション対応）
  - ✅ `POST /answers/:id/like`: いいね追加（重複チェックあり、ALREADY_LIKEDエラー）
  - ✅ `POST /answers/:id/comments`: コメント作成（認証必須、text: 1-200文字）
  - ✅ `POST /answers/upload-url`: 画像アップロード用署名付きURL取得（fileName, contentTypeを受け取る）
  - ⚠️ `GET /users/me`エンドポイントは存在しない → `/users/:id`を現在のユーザーIDで呼び出す
  - ⚠️ いいね一覧取得APIは未実装 → 回答詳細に`likeCount`のみ含まれる（ユーザーリストなし）

- **Implications**:
  - モバイルクライアントは既存APIを直接利用可能
  - `UserApi`に`getCurrentUser()`, `updateProfile()`, `getUserById()`, `getUserChampionships()`, `getUserAnswers()`を実装
  - `AnswerApi`は既存の`getComments()`, `createComment()`, `addLike()`を活用
  - いいね一覧表示機能（Requirement 5.3）はlikeCountのみ表示する仕様に調整するか、バックエンド拡張を提案

### 画像処理パッケージの選定

- **Context**: 要件12（画像アップロード）で画像選択・リサイズ・圧縮が必要
- **Sources Consulted**:
  - [image_picker pub.dev](https://pub.dev/packages/image_picker)
  - [flutter_image_compress pub.dev](https://pub.dev/packages/flutter_image_compress)
- **Findings**:
  - `image_picker ^1.0.0`: ギャラリー・カメラからの画像選択、iOS/Android対応
    - ネイティブ権限設定が必要（Info.plist, AndroidManifest.xml）
    - 軽量で安定、メンテナンス活発
  - `flutter_image_compress ^2.1.0`: 画像リサイズ・圧縮
    - ネイティブ実装（高速）
    - 最大解像度、品質指定可能
    - JPEG/PNG/HEIC対応
- **Implications**:
  - pubspec.yamlに両パッケージを追加
  - 画像選択後、1024x1024ピクセルにリサイズ、品質85%で圧縮
  - `core/utils/image_helper.dart`に画像処理ヘルパーを実装

### オフラインキャッシング戦略

- **Context**: 要件11（オフライン対応）でキャッシュ戦略の設計が必要
- **Sources Consulted**:
  - 既存の`StorageService`実装
  - Flutter公式ドキュメント: データ永続化
- **Findings**:
  - **Phase 1 (MVP)**: `shared_preferences`のみ使用
    - 認証トークンとユーザー情報を保存（既存`StorageService`で実装済み）
    - 選手権一覧・詳細をJSON文字列でキャッシュ
    - キャッシュキー: `cache_championships_list_{status}`, `cache_championship_{id}`
    - TTL: 5分（タイムスタンプと比較）
  - **Phase 2 (拡張)**: Hiveへの移行を検討
    - 複雑なクエリや大量データには向かないが、現要件では不要
    - リレーショナルデータ管理が必要になった場合のみ導入

- **Implications**:
  - Phase 1では`StorageService`を拡張してキャッシュロジックを実装
  - `CacheService`クラスを新規作成し、TTL管理とキャッシュキー生成を一元化
  - ネットワークエラー時はキャッシュからフォールバック

### 認証UI実装方法

- **Context**: 要件1（認証機能）でサインイン画面の実装方法を選択する必要がある
- **Sources Consulted**:
  - [firebase_ui_auth pub.dev](https://pub.dev/packages/firebase_ui_auth)
  - Flutterプロジェクトの既存UI実装パターン
- **Findings**:
  - **Option A: firebase_ui_auth**
    - メリット: メール/パスワード、Google、Appleサインイン対応、UI実装不要
    - デメリット: カスタマイズ制限、パッケージサイズ増加（約2MB）
  - **Option B: カスタムサインイン画面**
    - メリット: 完全なデザインコントロール、軽量
    - デメリット: UI実装コスト高（2-3日）、バリデーションロジック実装

- **Implications**:
  - **推奨: Option B（カスタムサインイン画面）**
  - 理由:
    - 既存のプロジェクトはシンプルなUI設計
    - メール/パスワードのみのサインインで十分（OAuth不要）
    - firebase_ui_authはオーバースペック
  - 実装: `features/auth/presentation/pages/sign_in_page.dart`にカスタム実装
  - Firebase AuthのemailAndPassword認証のみ使用

### ネットワーク状態監視

- **Context**: 要件11.3（ネットワーク復帰時の自動再取得）
- **Sources Consulted**:
  - [connectivity_plus pub.dev](https://pub.dev/packages/connectivity_plus)
- **Findings**:
  - `connectivity_plus ^5.0.0`: ネットワーク接続状態の監視
    - WiFi/モバイルデータ/オフラインを区別
    - StreamProviderでリアルタイム監視可能
  - オフラインインジケーター表示位置: AppBarに常駐（赤色バナー）
  - ネットワーク復帰時の自動リフレッシュ: `connectivity_plus`のStreamを監視し、オフライン→オンライン遷移時にProviderを無効化

- **Implications**:
  - `connectivity_plus`パッケージ追加
  - `core/providers.dart`に`connectivityProvider`を追加
  - 各画面でネットワーク状態を監視し、復帰時に`ref.invalidate()`でデータリフレッシュ

## Architecture Pattern Evaluation

### Provider構成の選択

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Option A: 集約型 | 全Provider を `core/providers.dart` に集約 | シンプル、ファイル数削減 | ファイル肥大化、単一責任原則違反 | Phase 1で採用 |
| Option B: 分散型 | 機能別に Provider ファイルを分離 | 関心の分離、テスタビリティ | ファイル数増加、初期実装コスト高 | Phase 2で移行検討 |

### 画像アップロードフロー

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| クライアント圧縮 | クライアント側で圧縮してからアップロード | 帯域削減、UX向上、バックエンド負荷軽減 | ネイティブ実装依存 | **選択** |
| バックエンド圧縮 | 元画像をアップロードしてバックエンドで圧縮 | クライアント実装シンプル | ネットワーク帯域消費大、UX低下 | 不採用 |

### エラー表示戦略

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| グローバルSnackBar | 全エラーをグローバルハンドラでSnackBar表示 | 一貫性、実装シンプル | コンテキスト不明確、画面遷移時の表示問題 | 不採用 |
| 画面ごとのErrorView | 各画面でAsyncValue.error時にエラーウィジェット表示 | コンテキスト明確、柔軟なUI | 実装が各画面に分散 | **選択** |

## Design Decisions

### Decision: ハイブリッドアプローチ（Phase 1 + Phase 2）

- **Context**: ギャップ分析で3つの実装アプローチを評価
- **Alternatives Considered**:
  1. Option A: 既存コンポーネントを拡張 — `core/providers.dart`に全Provider追加、既存ページにUI実装
  2. Option B: 新規コンポーネントを作成 — 機能別にProvider分離、共通ウィジェット抽出
  3. Option C: ハイブリッド — Phase 1で既存拡張、Phase 2でリファクタリング
- **Selected Approach**: Option C（ハイブリッド）
- **Rationale**:
  - Phase 1で動作するMVPを早期にデリバリー可能
  - 既存の堅牢なAPI基盤を最大限活用
  - Phase 2でコードレビュー後にリファクタリング余地を残す
- **Trade-offs**:
  - メリット: リスク分散、早期フィードバック
  - デメリット: Phase 1の実装が技術的負債になる可能性
- **Follow-up**: Phase 2でProvider分割、共通ウィジェット抽出、テストカバレッジ向上

### Decision: いいね一覧表示の簡略化

- **Context**: 要件5.3でいいね一覧表示が必要だが、バックエンドAPIに`GET /answers/:id/likes`が存在しない
- **Alternatives Considered**:
  1. バックエンドAPI拡張を提案 — いいね一覧エンドポイント追加
  2. いいね数のみ表示 — `likeCount`を表示、ユーザーリストは非表示
- **Selected Approach**: Option 2（いいね数のみ表示）
- **Rationale**:
  - MVP要件としてはいいね数の表示で十分
  - バックエンド拡張は追加工数が発生
  - Phase 2でユーザーフィードバックを得てから機能拡張を判断
- **Trade-offs**:
  - メリット: 早期デリバリー、実装コスト削減
  - デメリット: UX制限（誰がいいねしたかわからない）
- **Follow-up**: ユーザーフィードバック収集後、必要に応じてバックエンドAPI拡張

### Decision: 画像圧縮パラメータ

- **Context**: 要件12で画像リサイズ・圧縮の仕様決定が必要
- **Alternatives Considered**:
  1. 1024x1024px, 品質85% — Googleベストプラクティス
  2. 800x800px, 品質90% — より高品質、ファイルサイズ増
  3. 1024x1024px, 品質70% — より軽量、品質低下
- **Selected Approach**: Option 1（1024x1024px, 品質85%）
- **Rationale**:
  - モバイル画面での表示に最適な解像度
  - 品質とファイルサイズのバランスが良好
  - Googleのモバイル画像最適化ガイドラインに準拠
- **Trade-offs**:
  - メリット: UX良好、ネットワーク帯域効率的
  - デメリット: 高解像度デバイスではやや粗い
- **Follow-up**: ユーザーフィードバックに応じて調整

### Decision: キャッシュTTL設定

- **Context**: 要件11でキャッシュ有効期限の設定が必要
- **Alternatives Considered**:
  1. 選手権一覧5分、詳細10分 — 頻繁に更新
  2. 選手権一覧10分、詳細30分 — ネットワーク負荷軽減
  3. 選手権一覧3分、詳細5分 — リアルタイム性重視
- **Selected Approach**: Option 1（選手権一覧5分、詳細10分）
- **Rationale**:
  - 選手権一覧は頻繁に閲覧されるためキャッシュ効果大
  - 詳細は変更頻度が低いため長めのTTL
  - リアルタイム性とキャッシュ効果のバランス
- **Trade-offs**:
  - メリット: ネットワーク負荷削減、オフライン閲覧可能
  - デメリット: 最大5-10分のデータ遅延
- **Follow-up**: 実運用データに基づいて最適化

## Risks & Mitigations

- **リスク1: ネイティブ権限設定の複雑性**
  - 緩和策: `image_picker`公式ドキュメントに従って、Info.plist（iOS）とAndroidManifest.xml（Android）を設定。CI/CDでビルド時に検証。
- **リスク2: オフラインキャッシュの不整合**
  - 緩和策: キャッシュ更新時にタイムスタンプを保存、TTL超過時は自動再取得。ネットワーク復帰時に`ref.invalidate()`で強制リフレッシュ。
- **リスク3: Firebase Auth トークン期限切れ時のUX**
  - 緩和策: `ErrorInterceptor`でトークン自動リフレッシュ、失敗時は自動ログアウトとサインイン画面遷移。GoRouterのredirectロジックで実装。
- **リスク4: 画像アップロード失敗時のリトライ**
  - 緩和策: `UploadService`にリトライロジック実装（最大3回、指数バックオフ）。ユーザーには明確なエラーメッセージとリトライボタン提供。
- **リスク5: 大量の選手権データによるパフォーマンス低下**
  - 緩和策: ページネーション（20件/ページ）、仮想スクロール（ListView.builder）、画像遅延ロード（cached_network_image）導入検討。

## References
- [Riverpod公式ドキュメント](https://riverpod.dev) — 状態管理パターン、AsyncValue使用法
- [Flutter公式: ネットワーキング](https://docs.flutter.dev/cookbook/networking) — HTTP クライアント、エラーハンドリング
- [image_picker pub.dev](https://pub.dev/packages/image_picker) — 画像選択、ネイティブ権限設定
- [flutter_image_compress pub.dev](https://pub.dev/packages/flutter_image_compress) — 画像圧縮、リサイズパラメータ
- [connectivity_plus pub.dev](https://pub.dev/packages/connectivity_plus) — ネットワーク状態監視
- [Google Cloud Storage公式ドキュメント](https://cloud.google.com/storage/docs/uploading-objects#storage-upload-object-client-libraries) — 署名付きURL、アップロード手順
