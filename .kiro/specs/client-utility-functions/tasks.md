# Implementation Plan

## Task 1: プロジェクト依存関係とディレクトリ構造のセットアップ

- [x] 1.1 必要なパッケージを追加する
  - dio、firebase_auth、firebase_core、shared_preferences、intlパッケージを追加
  - 設計書指定のバージョンを適用（dio ^5.4.0、firebase_auth ^5.0.0、shared_preferences ^2.2.0、intl ^0.19.0）
  - 依存関係を解決して正常にビルドできることを確認
  - _Requirements: 1.1, 2.1, 7.1, 8.1_

- [x] 1.2 (P) Coreディレクトリ構造を作成する
  - api、auth、services、utils、modelsの各ディレクトリを作成
  - 各ディレクトリにbarrelファイルを配置して再エクスポートを設定
  - _Requirements: 1.1_

## Task 2: エラーハンドリング基盤の構築

- [x] 2.1 API例外クラス階層を実装する
  - sealed classとしてApiException基底クラスを定義し、message、code、statusCodeプロパティを持たせる
  - クライアントエラー（4xx）用のClientException、認証エラー用のUnauthorizedException、認可エラー用のForbiddenExceptionを実装
  - リソース不在用のNotFoundException、競合用のConflictException、サーバーエラー用のServerExceptionを実装
  - ネットワーク障害用のNetworkException、タイムアウト用のTimeoutExceptionを実装
  - バックエンドエラーコード（UNAUTHORIZED、NOT_FOUND等）との対応マッピングを定義
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

## Task 3: 認証サービスの実装

- [x] 3.1 AuthServiceを実装する
  - Firebase Authとの連携でユーザー状態の変更を監視するStreamを提供
  - 現在のログイン状態とユーザー情報を取得する機能を構築
  - ID Tokenの取得機能（通常取得および強制リフレッシュ）を実装
  - ログアウト処理を実装
  - _Requirements: 2.3, 2.4, 2.5_

- [x] 3.2 (P) AuthProviderを実装する
  - 認証状態の変更をStreamProviderとして公開
  - 現在のユーザー情報を取得するProviderを定義
  - ログイン状態を判定するProviderを定義
  - _Requirements: 2.4_

## Task 4: HTTPクライアント基盤の構築

- [x] 4.1 ApiClientを実装する
  - 環境変数からベースURLを取得してDioインスタンスを設定
  - タイムアウト30秒を設定
  - GET、POST、PUT、PATCH、DELETEメソッドを提供
  - Content-Type: application/jsonヘッダーを自動付与
  - JSONレスポンスを指定された型にデシリアライズする機能を提供
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 4.2 AuthInterceptorを実装する
  - リクエスト送信前にAuthServiceからFirebase ID Tokenを取得
  - 認証済みユーザーの場合、AuthorizationヘッダーにBearerトークンを付与
  - 未認証ユーザーの場合はヘッダー付与をスキップ
  - _Requirements: 2.1_

- [x] 4.3 ErrorInterceptorを実装する
  - HTTPエラーレスポンスを適切なApiExceptionサブクラスに変換
  - 4xx、5xx、ネットワーク障害、タイムアウトを分類
  - バックエンドのエラーレスポンスボディからメッセージを抽出して保持
  - TOKEN_EXPIREDエラー時にトークンを強制リフレッシュしてリクエストを再試行
  - リトライ失敗時にユーザーを未認証状態に遷移させる
  - _Requirements: 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 3.5_

## Task 5: ドメインモデルとページングの実装

- [x] 5.1 (P) 共通列挙型を定義する
  - ChampionshipStatus（recruiting、selecting、announced）を定義
  - AwardType（grandPrize、prize、specialPrize）を定義
  - ChampionshipSort（newest、popular）、AnswerSort（score、newest）を定義
  - JSONシリアライズ/デシリアライズ用の変換処理を追加
  - _Requirements: 4.1, 4.3_

- [x] 5.2 (P) ページングモデルを実装する
  - PaginatedResponseジェネリッククラスを実装（items、paginationを保持）
  - PaginationInfoクラス（page、limit、total、totalPages）を実装
  - hasNextPage、nextPageOffsetゲッターを提供
  - PaginationParamsクラスとクエリパラメータ変換機能を実装
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 5.3 (P) ドメインモデルを実装する
  - Championship、ChampionshipDetailモデルを実装（fromJson含む）
  - Answer、Like、Commentモデルを実装（fromJson含む）
  - UserProfile、UserSummaryモデルを実装（fromJson含む）
  - _Requirements: 4.1, 4.3, 4.5_

## Task 6: APIエンドポイント関数の実装

- [x] 6.1 ChampionshipApiを実装する
  - 選手権一覧取得機能（ページング、ステータスフィルタ、ソート対応）
  - 選手権詳細取得機能
  - 選手権作成機能（タイトル、説明、期間を指定）
  - 選手権強制終了機能
  - 結果発表機能（サマリーコメント付き）
  - _Requirements: 4.1, 4.2_

- [x] 6.2 (P) AnswerApiを実装する
  - 回答一覧取得機能（ページング、ソート対応）
  - 回答投稿機能（テキスト、画像URL）
  - 回答編集機能
  - 受賞設定機能（受賞タイプ、コメント）
  - いいね追加機能
  - コメント一覧取得・投稿機能
  - _Requirements: 4.3, 4.4_

- [x] 6.3 (P) UserApiを実装する
  - ユーザープロフィール取得機能
  - プロフィール更新機能（表示名、自己紹介、アバター、Twitter URL）
  - ユーザーの選手権一覧取得機能
  - ユーザーの回答一覧取得機能
  - _Requirements: 4.5_

## Task 7: 画像アップロードサービスの実装

- [x] 7.1 UploadServiceを実装する
  - ファイル形式検証（JPEG、PNG、GIF、WebP）機能
  - ファイルサイズ検証（10MB上限）機能
  - 署名付きURL取得API呼び出し
  - GCSへの直接アップロード処理
  - アップロード進捗（0-100%）のコールバック通知
  - アップロード失敗時のリトライ可能エラーを定義
  - _Requirements: 4.6, 6.1, 6.2, 6.3, 6.4, 6.5_

## Task 8: ユーティリティ関数の実装

- [x] 8.1 (P) DateTimeUtilsを実装する
  - ISO 8601文字列とDateTime相互変換機能
  - 相対時間表示変換（「3分前」「2日前」等）
  - 日本語日付フォーマット（「2024年1月15日」）
  - 日本語日時フォーマット（「2024年1月15日 14:30」）
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 8.2 (P) StorageServiceを実装する
  - SharedPreferencesのラッパーとして実装
  - 文字列、整数、真偽値の保存・取得機能
  - キーの削除機能
  - JSONオブジェクトのシリアライズ/デシリアライズ保存・取得
  - 型安全なジェネリック取得関数
  - 全データクリア機能
  - _Requirements: 8.1, 8.2, 8.3_

## Task 9: Riverpod Provider統合

- [x] 9.1 サービスProviderを定義する
  - ApiClientのProvider定義（インターセプター統合）
  - ChampionshipApi、AnswerApi、UserApiのProvider定義
  - UploadService、StorageServiceのProvider定義
  - 依存関係の注入を設定
  - _Requirements: 1.1, 4.1, 4.3, 4.5, 6.1, 8.1_

## Task 10: 統合検証

- [x] 10.1 エンドツーエンド動作確認
  - 認証フロー全体（トークン取得→API呼び出し→期限切れリトライ）の動作確認
  - 各APIエンドポイント関数の疎通確認
  - エラーハンドリングの動作確認（各種エラーケース）
  - アップロードフローの動作確認
  - _Requirements: 1.1, 2.1, 2.2, 3.1, 4.1, 6.1_
