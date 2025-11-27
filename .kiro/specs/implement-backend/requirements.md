# Requirements Document

## Introduction

「みんなの選手権」アプリケーションのバックエンドAPIを実装する。Hono フレームワークを使用し、Cloud Run 上で動作するREST APIを構築する。Firebase Authentication による認証、Prisma ORM によるCloud SQL (MySQL) へのデータアクセス、Cloud Storage への画像アップロード機能を提供する。

## Requirements

### Requirement 1: プロジェクト基盤とセットアップ
**Objective:** As a 開発者, I want プロジェクトの基盤が整備されている, so that 一貫性のある開発環境で効率的に開発を進められる

#### Acceptance Criteria
1. The Backend API shall TypeScriptで記述され、Honoフレームワークを使用する
2. The Backend API shall Prisma ORMを使用してCloud SQL (MySQL 8.0) に接続する
3. The Backend API shall Firebase Admin SDKを使用して認証トークンを検証する
4. The Backend API shall 環境変数でデータベースURL、Firebase設定、GCS設定を管理する
5. The Backend API shall ポート8080でHTTPリクエストを受け付ける

### Requirement 2: データベーススキーマ
**Objective:** As a 開発者, I want データモデルが正しく定義されている, so that アプリケーションのデータを永続化できる

#### Acceptance Criteria
1. The Prisma Schema shall User, Championship, Answer, Like, Comment エンティティを定義する
2. The User Entity shall id (UUID), firebase_uid (ユニーク), display_name (30文字), avatar_url, bio (200文字), twitter_url, created_at, updated_at フィールドを持つ
3. The Championship Entity shall id, user_id (FK), title (50文字), description (500文字), status (募集中/選定中/結果発表), start_at, end_at, summary_comment (1000文字), created_at, updated_at フィールドを持つ
4. The Answer Entity shall id, championship_id (FK), user_id (FK), text (300文字), image_url, award_type (最優秀賞/入賞/特別賞/null), award_comment (300文字), like_count, comment_count, created_at, updated_at フィールドを持つ
5. The Like Entity shall id, answer_id (FK), user_id (FK), created_at フィールドを持ち、(answer_id, user_id) でユニーク制約を持つ
6. The Comment Entity shall id, answer_id (FK), user_id (FK), text (200文字), created_at フィールドを持つ

### Requirement 3: 認証ミドルウェア
**Objective:** As a システム管理者, I want APIエンドポイントが適切に保護されている, so that 認証済みユーザーのみが保護されたリソースにアクセスできる

#### Acceptance Criteria
1. When Authorizationヘッダーが提供される, the Auth Middleware shall Firebase ID トークンを検証する
2. If 有効なトークンが提供される, then the Auth Middleware shall リクエストコンテキストにユーザー情報を設定する
3. If 無効または期限切れのトークンが提供される, then the Auth Middleware shall 401 Unauthorized レスポンスを返す
4. If Authorizationヘッダーが欠落している and エンドポイントが認証必須の場合, then the Auth Middleware shall 401 Unauthorized レスポンスを返す
5. The Auth Middleware shall 公開エンドポイント（GET /championships, GET /championships/:id 等）では認証を任意とする

### Requirement 4: 選手権API
**Objective:** As a ユーザー, I want 選手権を作成・閲覧・管理できる, so that お題を投稿し、参加者を募集できる

#### Acceptance Criteria
1. When GET /championships が呼び出される, the Championships API shall 選手権一覧をフィルタ（status）・ソート（新着順/人気順）オプション付きで返す
2. When GET /championships/:id が呼び出される, the Championships API shall 指定された選手権の詳細情報を返す
3. When POST /championships が認証済みユーザーから呼び出される, the Championships API shall 新しい選手権を作成する（タイトル50文字、説明500文字、募集期間最長2週間）
4. When PUT /championships/:id/force-end が主催者から呼び出される, the Championships API shall 選手権の締切を現在時刻に変更し、ステータスを「選定中」に遷移する
5. When PUT /championships/:id/publish-result が主催者から呼び出される, the Championships API shall 選手権のステータスを「結果発表」に遷移する
6. If 選手権が見つからない, then the Championships API shall 404 Not Found を返す
7. If 非主催者がforce-end または publish-result を試みる, then the Championships API shall 403 Forbidden を返す

### Requirement 5: 回答API
**Objective:** As a 参加者, I want 選手権に回答を投稿・編集できる, so that お題に対する回答を共有できる

#### Acceptance Criteria
1. When GET /championships/:id/answers が呼び出される, the Answers API shall 回答一覧をソート（スコア順/新着順）とページネーション（20件ずつ）付きで返す
2. When POST /championships/:id/answers が認証済みユーザーから呼び出される and 選手権が「募集中」である, the Answers API shall 新しい回答を作成する（テキスト300文字、画像URL任意）
3. When pUT /answers/:id が投稿者から呼び出される and 選手権が「募集中」である, the Answers API shall 回答のテキストまたは画像を更新する
4. When PUT /answers/:id/award が主催者から呼び出される and 選手権が「選定中」である, the Answers API shall 回答に受賞（最優秀賞/入賞/特別賞）を設定する
5. When POST /answers/upload-url が認証済みユーザーから呼び出される, the Answers API shall Cloud Storage への署名付きアップロードURLを生成して返す
6. If 選手権が「募集中」でない and 回答投稿/編集を試みる, then the Answers API shall 400 Bad Request を返す
7. If 非投稿者が回答編集を試みる, then the Answers API shall 403 Forbidden を返す

### Requirement 6: いいねAPI
**Objective:** As a ユーザー, I want 回答にいいねできる, so that 気に入った回答を評価できる

#### Acceptance Criteria
1. When POST /answers/:id/like が認証済みユーザーから呼び出される, the Likes API shall いいねを追加し、回答のlike_countをインクリメントする
2. If 同じユーザーが同じ回答に既にいいねしている, then the Likes API shall 409 Conflict を返す
3. The Likes API shall いいねの取り消し機能を提供しない（仕様による）

### Requirement 7: コメントAPI
**Objective:** As a ユーザー, I want 回答にコメントできる, so that 回答に対するフィードバックを共有できる

#### Acceptance Criteria
1. When GET /answers/:id/comments が呼び出される, the Comments API shall コメント一覧を投稿日時順で返す
2. When POST /answers/:id/comments が認証済みユーザーから呼び出される, the Comments API shall 新しいコメントを作成し（200文字以内）、回答のcomment_countをインクリメントする
3. The Comments API shall コメントの削除機能を提供しない（仕様による）

### Requirement 8: ユーザーAPI
**Objective:** As a ユーザー, I want プロフィールを管理できる, so that 自分の情報を公開・編集できる

#### Acceptance Criteria
1. When GET /users/:id が呼び出される, the Users API shall 指定ユーザーの公開プロフィール情報を返す
2. When PATCH /users/me が認証済みユーザーから呼び出される, the Users API shall 自分のプロフィール（display_name, bio, avatar_url, twitter_url）を更新する
3. When GET /users/:id/championships が呼び出される, the Users API shall 指定ユーザーが作成した選手権一覧を返す
4. When GET /users/:id/answers が呼び出される, the Users API shall 指定ユーザーが投稿した回答一覧を返す
5. If ユーザーが見つからない, then the Users API shall 404 Not Found を返す

### Requirement 9: エラーハンドリングとバリデーション
**Objective:** As a API利用者, I want 明確なエラーメッセージを受け取れる, so that 問題を迅速に特定・解決できる

#### Acceptance Criteria
1. The Backend API shall すべてのリクエストボディに対して入力バリデーションを実施する
2. If バリデーションエラーが発生する, then the Backend API shall 400 Bad Request と詳細なエラーメッセージを返す
3. The Backend API shall 一貫したエラーレスポンス形式（error.code, error.message）を使用する
4. If サーバーエラーが発生する, then the Backend API shall 500 Internal Server Error を返し、詳細をログに記録する

### Requirement 10: 選手権ステータス自動遷移
**Objective:** As a システム, I want 選手権のステータスが自動的に遷移する, so that 締切日を過ぎた選手権が適切に処理される

#### Acceptance Criteria
1. When 選手権の end_at が現在時刻を過ぎている and ステータスが「募集中」である, the Backend API shall ステータスを「選定中」として扱う（クエリ時に判定）
2. The Championships API shall 選手権一覧・詳細取得時にステータスを動的に計算して返す
