# Requirements Document

## Introduction

本仕様は、Flutter モバイルアプリケーションにおけるクライアント側ユーティリティ関数群の整備を定義する。バックエンドAPI（Hono/Node.js）との通信、Firebase認証連携、共通ロジックを体系的に実装し、各機能画面の開発基盤を提供する。

## Requirements

### Requirement 1: HTTPクライアント基盤

**Objective:** As a 開発者, I want 型安全で再利用可能なHTTPクライアント基盤, so that API呼び出しを統一的かつ効率的に実装できる。

#### Acceptance Criteria

1. The ApiClient shall バックエンドのベースURL（環境変数から取得）を設定して全リクエストに適用する
2. The ApiClient shall GET、POST、PUT、PATCH、DELETE メソッドに対応したリクエスト送信機能を提供する
3. When リクエストを送信するとき, the ApiClient shall Content-Type: application/json ヘッダーを自動付与する
4. When JSONレスポンスを受信したとき, the ApiClient shall 指定された型へのデシリアライズを実行する
5. The ApiClient shall リクエストタイムアウト（30秒）を設定し、超過時にタイムアウトエラーを発生させる

### Requirement 2: 認証トークン管理

**Objective:** As a ユーザー, I want Firebase認証トークンが自動的に管理される, so that 認証が必要なAPIを意識せず利用できる。

#### Acceptance Criteria

1. When 認証済みユーザーがAPIリクエストを送信するとき, the ApiClient shall Firebase ID Token を Authorization ヘッダーに自動付与する
2. When ID Token が期限切れの場合, the ApiClient shall 自動的にトークンをリフレッシュしてリクエストを再試行する
3. When トークンリフレッシュに失敗したとき, the ApiClient shall ユーザーを未認証状態に遷移させ、認証エラーを通知する
4. The AuthService shall 現在のログイン状態（ログイン中/未ログイン）を取得する機能を提供する
5. The AuthService shall ログアウト時にローカルのトークン情報をクリアする

### Requirement 3: エラーハンドリング

**Objective:** As a 開発者, I want 統一されたエラーハンドリング機構, so that エラー処理を一貫して実装できる。

#### Acceptance Criteria

1. When APIが4xxエラーを返したとき, the ApiClient shall クライアントエラー（バリデーションエラー、認証エラー等）として分類する
2. When APIが5xxエラーを返したとき, the ApiClient shall サーバーエラーとして分類する
3. When ネットワーク接続に失敗したとき, the ApiClient shall ネットワークエラーとして分類する
4. The ApiError shall エラーコード、メッセージ、HTTPステータスを含む構造化されたエラー情報を提供する
5. When APIがエラーレスポンスボディを返したとき, the ApiClient shall バックエンドのエラーメッセージを抽出して保持する

### Requirement 4: APIエンドポイント関数

**Objective:** As a 開発者, I want 各APIエンドポイントに対応する型安全な関数, so that IDE補完を活用して効率的にAPI呼び出しを実装できる。

#### Acceptance Criteria

1. The ChampionshipApi shall 選手権一覧取得（ページング、フィルタ、ソート対応）関数を提供する
2. The ChampionshipApi shall 選手権詳細取得、作成、強制終了、結果発表の関数を提供する
3. The AnswerApi shall 回答一覧取得、投稿、編集、受賞設定の関数を提供する
4. The AnswerApi shall いいね追加、コメント一覧取得、コメント投稿の関数を提供する
5. The UserApi shall ユーザープロフィール取得、更新、選手権一覧、回答一覧取得の関数を提供する
6. The UploadApi shall 画像アップロード用署名付きURL取得の関数を提供する

### Requirement 5: ページングユーティリティ

**Objective:** As a 開発者, I want ページング処理の共通化, so that リスト表示画面で統一されたページング実装ができる。

#### Acceptance Criteria

1. The PaginatedResponse shall 総件数、現在のオフセット、取得件数、データリストを含む構造を提供する
2. The PaginationParams shall limit、offset、sortBy、orderのパラメータを型安全に管理する
3. When 次ページが存在するとき, the PaginatedResponse shall hasNextPage を true で返す
4. The PaginationUtils shall 次ページのオフセット計算を行うヘルパー関数を提供する

### Requirement 6: 画像アップロードユーティリティ

**Objective:** As a ユーザー, I want 画像を簡単にアップロードできる, so that 回答に画像を添付できる。

#### Acceptance Criteria

1. When 画像をアップロードするとき, the UploadService shall 署名付きURLを取得してGCSに直接アップロードする
2. While アップロード中, the UploadService shall 進捗率（0-100%）を通知する
3. If アップロードに失敗したとき, the UploadService shall リトライ可能なエラーを返す
4. The UploadService shall 許可されたファイル形式（JPEG、PNG、GIF、WebP）を検証する
5. The UploadService shall ファイルサイズ上限（10MB）を検証する

### Requirement 7: 日付・時刻ユーティリティ

**Objective:** As a 開発者, I want 日付・時刻の変換処理の共通化, so that APIとの日付データのやり取りを統一できる。

#### Acceptance Criteria

1. The DateTimeUtils shall ISO 8601形式の文字列をDateTime型に変換する
2. The DateTimeUtils shall DateTime型をISO 8601形式の文字列に変換する
3. The DateTimeUtils shall 相対時間表示（「3分前」「2日前」等）への変換を行う
4. The DateTimeUtils shall 日本語フォーマット（「2024年1月15日」等）への変換を行う

### Requirement 8: ローカルストレージユーティリティ

**Objective:** As a 開発者, I want ローカルストレージへのアクセスを共通化, so that 設定やキャッシュの保存を統一的に実装できる。

#### Acceptance Criteria

1. The StorageService shall キーバリュー形式でのデータ保存・取得・削除機能を提供する
2. The StorageService shall JSON形式のオブジェクトをシリアライズ/デシリアライズして保存・取得する
3. The StorageService shall 型安全なジェネリック関数として値を取得する機能を提供する
