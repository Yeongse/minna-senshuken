# Implementation Plan

## Task 1: プロジェクト基盤のセットアップ

- [x] 1.1 Hono APIプロジェクトを初期化する
  - Node.js 20 LTSプロジェクトとしてTypeScript環境を構築する
  - Hono、Zod、その他必要な依存パッケージをインストールする
  - ポート8080でHTTPリクエストを受け付けるサーバーを起動する
  - 環境変数の読み込み機能を設定する（DATABASE_URL、Firebase設定、GCS設定）
  - _Requirements: 1.1, 1.4, 1.5_

- [x] 1.2 Prismaとデータベース接続を設定する
  - Prisma CLIをインストールし、MySQL用に初期化する
  - Cloud SQL (MySQL 8.0) への接続設定を行う
  - PrismaClientをシングルトンパターンで管理する
  - _Requirements: 1.2_

- [x] 1.3 Firebase Admin SDKを設定する
  - firebase-adminパッケージをインストールする
  - サービスアカウント認証情報による初期化を実装する
  - 環境変数からFirebase設定を読み込む
  - _Requirements: 1.3_

## Task 2: データベーススキーマの定義

- [x] 2.1 Prismaスキーマでエンティティを定義する
  - Userエンティティ（UUID、firebase_uid、display_name、avatar_url、bio、twitter_url、タイムスタンプ）を定義する
  - Championshipエンティティ（UUID、user_id、title、description、status、start_at、end_at、summary_comment、タイムスタンプ）を定義する
  - Answerエンティティ（UUID、championship_id、user_id、text、image_url、award_type、award_comment、like_count、comment_count、タイムスタンプ）を定義する
  - Likeエンティティ（UUID、answer_id、user_id、created_at、ユニーク制約）を定義する
  - Commentエンティティ（UUID、answer_id、user_id、text、created_at）を定義する
  - ChampionshipStatusとAwardTypeの列挙型を定義する
  - 各フィールドに適切な文字数制限とインデックスを設定する
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 2.2 マイグレーションを実行する
  - 初期マイグレーションを作成してデータベースに適用する
  - Prisma Clientを生成する
  - _Requirements: 2.1_

## Task 3: 共通基盤の実装

- [x] 3.1 エラーハンドリングとバリデーション基盤を構築する
  - 一貫したエラーレスポンス形式（error.code、error.message）を定義する
  - エラーコード定数（UNAUTHORIZED、FORBIDDEN、NOT_FOUND、VALIDATION_ERROR等）を定義する
  - Honoのグローバルエラーハンドラーを実装する
  - Zodバリデーションエラーを400レスポンスに変換する
  - サーバーエラー時のログ記録と500レスポンスを実装する
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [x] 3.2 (P) ページネーションユーティリティを実装する
  - ページネーションパラメータ（page、limit）のバリデーションを実装する
  - ページネーション結果（items、pagination）のレスポンス形式を統一する
  - デフォルト20件、最大100件の制限を設定する
  - _Requirements: 5.1_

- [x] 3.3 (P) 選手権ステータスの動的計算ロジックを実装する
  - end_atと現在時刻を比較してステータスを判定する関数を作成する
  - データベースのステータス値と計算結果を組み合わせる
  - 募集中でend_atを過ぎている場合は選定中として返す
  - _Requirements: 10.1, 10.2_

## Task 4: 認証ミドルウェアの実装

- [x] 4.1 Firebase認証ミドルウェアを実装する
  - AuthorizationヘッダーからBearerトークンを抽出する
  - Firebase Admin SDKのverifyIdTokenでトークンを検証する
  - 有効なトークンの場合、ユーザー情報をコンテキストに設定する
  - 無効または期限切れのトークンで401 Unauthorizedを返す
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 4.2 オプショナル認証ミドルウェアを実装する
  - 認証なしでもリクエストを許可するミドルウェアを作成する
  - トークンがある場合のみユーザー情報を設定する
  - 公開エンドポイント用に使用する
  - _Requirements: 3.5_

- [x] 4.3 ユーザー自動登録機能を実装する
  - Firebase UIDからユーザーを検索する
  - ユーザーが存在しない場合は新規作成する
  - 初期表示名をFirebaseの情報から設定する
  - _Requirements: 3.2_

## Task 5: ユーザーAPIの実装

- [x] 5.1 (P) ユーザー取得エンドポイントを実装する
  - GET /users/:id で指定ユーザーの公開プロフィールを返す
  - ユーザーが存在しない場合は404を返す
  - _Requirements: 8.1, 8.5_

- [x] 5.2 (P) プロフィール更新エンドポイントを実装する
  - PATCH /users/me で自分のプロフィールを更新する
  - display_name（30文字）、bio（200文字）、avatar_url、twitter_urlを更新可能にする
  - 認証必須、入力バリデーションを実施する
  - _Requirements: 8.2_

- [x] 5.3 (P) ユーザーの投稿履歴エンドポイントを実装する
  - GET /users/:id/championships でユーザーが作成した選手権一覧を返す
  - GET /users/:id/answers でユーザーが投稿した回答一覧を返す
  - ページネーションを適用する
  - ユーザーが存在しない場合は404を返す
  - _Requirements: 8.3, 8.4, 8.5_

## Task 6: 選手権APIの実装

- [x] 6.1 選手権一覧・詳細取得エンドポイントを実装する
  - GET /championships で選手権一覧を返す
  - ステータスフィルタ（募集中、選定中、結果発表）を実装する
  - ソート（新着順、人気順）を実装する
  - ページネーションを適用する
  - GET /championships/:id で選手権詳細を返す
  - 存在しない選手権には404を返す
  - 取得時にステータスを動的に計算して返す
  - _Requirements: 4.1, 4.2, 4.6, 10.2_

- [x] 6.2 選手権作成エンドポイントを実装する
  - POST /championships で新規選手権を作成する
  - タイトル（50文字）、説明（500文字）、募集期間（最長2週間）をバリデーションする
  - 認証必須、作成者をuser_idに設定する
  - 開始日を現在時刻、終了日を期間から計算する
  - _Requirements: 4.3_

- [x] 6.3 選手権強制終了エンドポイントを実装する
  - PUT /championships/:id/force-end で選手権を強制終了する
  - 主催者のみ実行可能（403 Forbidden）
  - 締切日を現在時刻に変更し、ステータスを選定中に遷移する
  - 存在しない選手権には404を返す
  - _Requirements: 4.4, 4.6, 4.7_

- [x] 6.4 結果発表エンドポイントを実装する
  - PUT /championships/:id/publish-result で結果を発表する
  - 主催者のみ実行可能（403 Forbidden）
  - ステータスを結果発表に遷移する
  - 総評コメント（1000文字）を保存可能にする
  - 存在しない選手権には404を返す
  - _Requirements: 4.5, 4.6, 4.7_

## Task 7: 回答APIの実装

- [x] 7.1 回答一覧取得エンドポイントを実装する
  - GET /championships/:id/answers で回答一覧を返す
  - ソート（スコア順、新着順）を実装する
  - スコア計算（いいね数 + コメント数 × 0.5）を実装する
  - ページネーション（20件ずつ）を適用する
  - 存在しない選手権には404を返す
  - _Requirements: 5.1_

- [x] 7.2 回答投稿エンドポイントを実装する
  - POST /championships/:id/answers で新規回答を投稿する
  - テキスト（300文字）、画像URL（任意）をバリデーションする
  - 選手権が募集中の場合のみ投稿可能（400 Bad Request）
  - 認証必須、投稿者をuser_idに設定する
  - 存在しない選手権には404を返す
  - _Requirements: 5.2, 5.6_

- [x] 7.3 回答編集エンドポイントを実装する
  - PUT /answers/:id で回答を編集する
  - テキスト、画像URLを更新可能にする
  - 投稿者のみ編集可能（403 Forbidden）
  - 選手権が募集中の場合のみ編集可能（400 Bad Request）
  - 存在しない回答には404を返す
  - _Requirements: 5.3, 5.6, 5.7_

- [x] 7.4 受賞設定エンドポイントを実装する
  - PUT /answers/:id/award で受賞を設定する
  - 受賞タイプ（最優秀賞、入賞、特別賞、null）を設定可能にする
  - 受賞コメント（300文字）を保存可能にする
  - 選手権主催者のみ設定可能（403 Forbidden）
  - 選手権が選定中の場合のみ設定可能（400 Bad Request）
  - 存在しない回答には404を返す
  - _Requirements: 5.4, 5.6, 5.7_

## Task 8: 画像アップロード機能の実装

- [x] 8.1 Cloud Storage署名付きURL生成を実装する
  - @google-cloud/storageライブラリを設定する
  - POST /answers/upload-url で署名付きアップロードURLを生成する
  - ファイルパス（uploads/{userId}/{timestamp}_{fileName}）を生成する
  - Content-Typeをimage/*に制限する
  - 有効期限15分のPUT用署名付きURLを返す
  - アップロード後のパブリックURLも返す
  - 認証必須
  - _Requirements: 5.5_

## Task 9: いいね・コメントAPIの実装

- [x] 9.1 (P) いいね追加エンドポイントを実装する
  - POST /answers/:id/like でいいねを追加する
  - 認証必須
  - 回答のlike_countをインクリメントする
  - 同じユーザーが同じ回答に重複いいねした場合は409 Conflictを返す
  - 存在しない回答には404を返す
  - いいねの取り消し機能は提供しない
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 9.2 (P) コメント一覧取得エンドポイントを実装する
  - GET /answers/:id/comments でコメント一覧を返す
  - 投稿日時順でソートする
  - ページネーションを適用する
  - 存在しない回答には404を返す
  - _Requirements: 7.1_

- [x] 9.3 (P) コメント投稿エンドポイントを実装する
  - POST /answers/:id/comments でコメントを投稿する
  - テキスト（200文字）をバリデーションする
  - 認証必須
  - 回答のcomment_countをインクリメントする
  - 存在しない回答には404を返す
  - コメントの削除機能は提供しない
  - _Requirements: 7.2, 7.3_

## Task 10: ルート統合とAPIサーバー完成

- [x] 10.1 全ルートをAPIサーバーに統合する
  - Championships Routes、Answers Routes、Users Routesを統合する
  - 認証ミドルウェアを適切なルートに適用する
  - エラーハンドラーをグローバルに設定する
  - ヘルスチェックエンドポイント（GET /health）を追加する
  - _Requirements: 1.1, 1.5_

- [x] 10.2 統合テストでAPIの動作を検証する
  - 認証フローの動作を確認する
  - 選手権ライフサイクル（作成→強制終了→結果発表）を検証する
  - 回答投稿・編集・受賞設定フローを検証する
  - いいね・コメント機能を検証する
  - エラーレスポンス形式の一貫性を確認する
  - _Requirements: 1.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1, 9.1_
