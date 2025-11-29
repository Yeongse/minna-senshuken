# Requirements Document

## Project Description (Input)
モバイルクライアントの実装

## Introduction

本要件定義書は、「みんなの選手権」プラットフォームのFlutterモバイルアプリケーションにおいて、既存のページレイアウトとルーティング構造を維持しつつ、未実装のビジネスロジック、API連携、状態管理機能を完成させるための要件をまとめたものである。

現状のモバイルアプリには以下のページが定義されているが、UI表示のみでバックエンドAPIとの連携やデータの永続化、エラーハンドリングなどの実装が不足している：

- ホーム画面（選手権一覧）
- 選手権詳細画面（回答一覧含む）
- 選手権作成画面
- 回答詳細画面
- 回答作成画面
- 回答編集画面
- プロフィール画面
- プロフィール編集画面
- ユーザー詳細画面

本要件では、これらの画面における完全な機能実装を目指す。

## Requirements

### Requirement 1: 認証機能

**Objective:** ユーザーとして、Firebase Authenticationを使用してアプリにログイン・ログアウトできるようにすることで、自分の投稿を管理し、パーソナライズされた体験を得られる

#### Acceptance Criteria

1. When ユーザーがアプリを初回起動する, the Mobile App shall Firebase Authentication経由でサインイン画面を表示する
2. When ユーザーがサインインに成功する, the Mobile App shall ユーザーのFirebase UIDを取得し、ローカルストレージに認証状態を保存する
3. When ユーザーがログアウトボタンをタップする, the Mobile App shall Firebase Authenticationからサインアウトし、ローカルストレージの認証情報をクリアする
4. While ユーザーがログイン済みである, the Mobile App shall 各API リクエストのAuthorizationヘッダーにFirebase ID Tokenを自動付与する
5. If Firebase ID Tokenの有効期限が切れている, then the Mobile App shall トークンを自動更新してからリクエストを送信する
6. The Mobile App shall アプリ起動時に前回のログイン状態を復元し、ログイン済みであればホーム画面を表示する

### Requirement 2: 選手権一覧表示機能

**Objective:** ユーザーとして、ホーム画面で募集中・選考中・発表済みの選手権一覧を閲覧できるようにすることで、興味のある企画を見つけられる

#### Acceptance Criteria

1. When ホーム画面が表示される, the Mobile App shall バックエンドAPIから選手権一覧を取得し、ステータス別に表示する
2. When 選手権一覧の取得に成功する, the Mobile App shall 各選手権のタイトル・説明・ステータス・開始日・終了日・主催者情報を表示する
3. While 選手権一覧を取得中である, the Mobile App shall ローディングインジケーターを表示する
4. If 選手権一覧の取得に失敗する, then the Mobile App shall エラーメッセージを表示し、再試行ボタンを提供する
5. When ユーザーが選手権項目をタップする, the Mobile App shall 選手権詳細画面に遷移する
6. The Mobile App shall 選手権一覧を最新の終了日順（新しい順）で表示する
7. When ユーザーが一覧を下方向にスワイプする, the Mobile App shall Pull-to-Refreshで選手権一覧を再取得する

### Requirement 3: 選手権詳細表示機能

**Objective:** ユーザーとして、選手権の詳細情報と投稿された回答一覧を閲覧できるようにすることで、企画の内容と他のユーザーの回答を把握できる

#### Acceptance Criteria

1. When 選手権詳細画面が表示される, the Mobile App shall バックエンドAPIから選手権詳細と回答一覧を取得し、表示する
2. When 選手権詳細の取得に成功する, the Mobile App shall タイトル・説明・ステータス・開始日・終了日・主催者情報・総括コメント（発表済みの場合）を表示する
3. When 回答一覧の取得に成功する, the Mobile App shall 各回答のテキスト・画像（ある場合）・いいね数・コメント数・受賞情報（ある場合）を表示する
4. While 選手権詳細または回答一覧を取得中である, the Mobile App shall ローディングインジケーターを表示する
5. If 選手権詳細の取得に失敗する, then the Mobile App shall エラーメッセージを表示し、再試行ボタンを提供する
6. When ユーザーが回答項目をタップする, the Mobile App shall 回答詳細画面に遷移する
7. Where 選手権のステータスがRECRUITINGである, the Mobile App shall 「回答を投稿」ボタンを表示する
8. When ユーザーが「回答を投稿」ボタンをタップする, the Mobile App shall 回答作成画面に遷移する

### Requirement 4: 選手権作成機能

**Objective:** ログイン済みユーザーとして、新しい選手権を作成できるようにすることで、自分が企画した大喜利テーマを他のユーザーに提供できる

#### Acceptance Criteria

1. When 選手権作成画面が表示される, the Mobile App shall タイトル・説明・終了日時の入力フォームを表示する
2. When ユーザーが全ての必須項目を入力し作成ボタンをタップする, the Mobile App shall バックエンドAPIに選手権作成リクエストを送信する
3. When 選手権作成リクエストに成功する, the Mobile App shall ホーム画面に戻り、成功メッセージを表示する
4. If タイトルが空または50文字を超える, then the Mobile App shall バリデーションエラーメッセージを表示する
5. If 説明が空または500文字を超える, then the Mobile App shall バリデーションエラーメッセージを表示する
6. If 終了日時が現在時刻より前である, then the Mobile App shall 「終了日時は未来の日時を指定してください」というエラーメッセージを表示する
7. While 選手権作成リクエストを送信中である, the Mobile App shall ローディング状態を表示し、作成ボタンを無効化する
8. If 選手権作成リクエストに失敗する, then the Mobile App shall エラーメッセージを表示し、ユーザーが再試行できるようにする

### Requirement 5: 回答詳細表示機能

**Objective:** ユーザーとして、回答の詳細情報といいね・コメント一覧を閲覧できるようにすることで、回答に対する評価や反応を確認できる

#### Acceptance Criteria

1. When 回答詳細画面が表示される, the Mobile App shall バックエンドAPIから回答詳細といいね・コメント一覧を取得し、表示する
2. When 回答詳細の取得に成功する, the Mobile App shall 回答テキスト・画像（ある場合）・投稿者情報・いいね数・コメント数・受賞情報（ある場合）を表示する
3. When いいね一覧の取得に成功する, the Mobile App shall いいねしたユーザーの表示名とアバターを一覧表示する
4. When コメント一覧の取得に成功する, the Mobile App shall 各コメントのテキスト・投稿者情報・投稿日時を表示する
5. While 回答詳細を取得中である, the Mobile App shall ローディングインジケーターを表示する
6. If 回答詳細の取得に失敗する, then the Mobile App shall エラーメッセージを表示し、再試行ボタンを提供する
7. Where ユーザーがログイン済みである, the Mobile App shall いいねボタンとコメント入力欄を表示する
8. When ユーザーがいいねボタンをタップする, the Mobile App shall バックエンドAPIにいいねリクエストを送信し、いいね数を即座に更新する
9. When ユーザーがコメントを入力し送信ボタンをタップする, the Mobile App shall バックエンドAPIにコメント投稿リクエストを送信し、コメント一覧を更新する

### Requirement 6: 回答作成機能

**Objective:** ログイン済みユーザーとして、選手権に対して回答を投稿できるようにすることで、企画に参加し自分のアイデアを共有できる

#### Acceptance Criteria

1. When 回答作成画面が表示される, the Mobile App shall 選手権のタイトル・説明と回答テキスト・画像選択の入力フォームを表示する
2. When ユーザーが画像選択ボタンをタップする, the Mobile App shall デバイスのギャラリーまたはカメラから画像を選択できるようにする
3. When ユーザーが画像を選択する, the Mobile App shall 選択した画像のプレビューを表示する
4. When ユーザーが回答テキストを入力し投稿ボタンをタップする, the Mobile App shall バックエンドAPIに回答作成リクエストを送信する
5. When 回答作成リクエストに成功する, the Mobile App shall 選手権詳細画面に戻り、成功メッセージを表示する
6. If 回答テキストが空または300文字を超える, then the Mobile App shall バリデーションエラーメッセージを表示する
7. While 回答作成リクエストを送信中である, the Mobile App shall ローディング状態を表示し、投稿ボタンを無効化する
8. If 回答作成リクエストに失敗する, then the Mobile App shall エラーメッセージを表示し、ユーザーが再試行できるようにする
9. Where ユーザーが画像を選択した, the Mobile App shall 画像をGoogle Cloud Storageにアップロードし、取得したURLを回答データに含める

### Requirement 7: 回答編集機能

**Objective:** ログイン済みユーザーとして、自分が投稿した回答を編集できるようにすることで、投稿内容を修正・改善できる

#### Acceptance Criteria

1. When 回答編集画面が表示される, the Mobile App shall 既存の回答データを取得し、テキスト・画像を編集フォームに表示する
2. When ユーザーが編集内容を変更し更新ボタンをタップする, the Mobile App shall バックエンドAPIに回答更新リクエストを送信する
3. When 回答更新リクエストに成功する, the Mobile App shall 回答詳細画面に戻り、成功メッセージを表示する
4. If 編集後の回答テキストが空または300文字を超える, then the Mobile App shall バリデーションエラーメッセージを表示する
5. While 回答更新リクエストを送信中である, the Mobile App shall ローディング状態を表示し、更新ボタンを無効化する
6. If 回答更新リクエストに失敗する, then the Mobile App shall エラーメッセージを表示し、ユーザーが再試行できるようにする
7. Where ユーザーが新しい画像を選択した, the Mobile App shall 新しい画像をアップロードし、古い画像URLを置き換える
8. The Mobile App shall ユーザーが投稿した回答のみ編集可能とし、他のユーザーの回答は編集できないようにする

### Requirement 8: プロフィール表示・編集機能

**Objective:** ログイン済みユーザーとして、自分のプロフィール情報を表示・編集できるようにすることで、アカウント情報を管理できる

#### Acceptance Criteria

1. When プロフィール画面が表示される, the Mobile App shall バックエンドAPIから現在のユーザー情報を取得し、表示名・アバター・自己紹介・TwitterURLを表示する
2. When ユーザーが編集ボタンをタップする, the Mobile App shall プロフィール編集画面に遷移する
3. When プロフィール編集画面が表示される, the Mobile App shall 表示名・アバター・自己紹介・TwitterURLの入力フォームを表示する
4. When ユーザーが編集内容を変更し保存ボタンをタップする, the Mobile App shall バックエンドAPIにユーザー情報更新リクエストを送信する
5. When ユーザー情報更新リクエストに成功する, the Mobile App shall プロフィール画面に戻り、成功メッセージを表示する
6. If 表示名が空または30文字を超える, then the Mobile App shall バリデーションエラーメッセージを表示する
7. If 自己紹介が200文字を超える, then the Mobile App shall バリデーションエラーメッセージを表示する
8. While ユーザー情報更新リクエストを送信中である, the Mobile App shall ローディング状態を表示し、保存ボタンを無効化する
9. If ユーザー情報更新リクエストに失敗する, then the Mobile App shall エラーメッセージを表示し、ユーザーが再試行できるようにする
10. Where ユーザーが新しいアバター画像を選択した, the Mobile App shall 画像をアップロードし、取得したURLをユーザー情報に含める

### Requirement 9: ユーザー詳細表示機能

**Objective:** ユーザーとして、他のユーザーのプロフィール情報と投稿一覧を閲覧できるようにすることで、そのユーザーの活動を把握できる

#### Acceptance Criteria

1. When ユーザー詳細画面が表示される, the Mobile App shall バックエンドAPIから指定ユーザーの情報と投稿一覧を取得し、表示する
2. When ユーザー情報の取得に成功する, the Mobile App shall 表示名・アバター・自己紹介・TwitterURLを表示する
3. When ユーザーの投稿一覧の取得に成功する, the Mobile App shall そのユーザーが主催した選手権と投稿した回答を一覧表示する
4. While ユーザー情報を取得中である, the Mobile App shall ローディングインジケーターを表示する
5. If ユーザー情報の取得に失敗する, then the Mobile App shall エラーメッセージを表示し、再試行ボタンを提供する

### Requirement 10: エラーハンドリング・状態管理

**Objective:** 開発者として、統一されたエラーハンドリングと状態管理の仕組みを実装することで、保守性の高いコードベースを維持できる

#### Acceptance Criteria

1. The Mobile App shall Riverpodを使用して全ての画面の状態管理を実装する
2. The Mobile App shall DioのInterceptorを使用してAPI リクエストのエラーハンドリングを一元管理する
3. When APIリクエストがHTTP 401エラーを返す, the Mobile App shall 自動的にログアウト処理を実行し、サインイン画面に遷移する
4. When APIリクエストがHTTP 400エラーを返す, the Mobile App shall エラーレスポンスからエラーメッセージを抽出し、ユーザーに表示する
5. When APIリクエストがHTTP 500エラーを返す, the Mobile App shall 「サーバーエラーが発生しました。しばらくしてから再度お試しください」というメッセージを表示する
6. If ネットワーク接続がない, then the Mobile App shall 「インターネット接続を確認してください」というメッセージを表示する
7. The Mobile App shall 全ての非同期処理にローディング状態とエラー状態を含むAsyncValueを使用する

### Requirement 11: オフライン対応・キャッシング

**Objective:** ユーザーとして、一度取得したデータをオフラインでも閲覧できるようにすることで、通信環境が不安定な場合でも快適に利用できる

#### Acceptance Criteria

1. The Mobile App shall shared_preferencesを使用して認証トークンとユーザー情報をローカルに保存する
2. When ユーザーがオフライン状態で画面を開く, the Mobile App shall 最後に取得したデータをキャッシュから表示し、「オフラインモード」の表示を行う
3. When ネットワーク接続が復帰する, the Mobile App shall 自動的にデータを再取得し、キャッシュを更新する
4. The Mobile App shall 選手権一覧・選手権詳細・ユーザー情報をキャッシュする
5. The Mobile App shall キャッシュデータには有効期限を設定し、古いデータは自動的に再取得する

### Requirement 12: 画像アップロード機能

**Objective:** ユーザーとして、回答やプロフィールに画像を添付できるようにすることで、視覚的に豊かなコンテンツを投稿できる

#### Acceptance Criteria

1. When ユーザーが画像選択ボタンをタップする, the Mobile App shall デバイスのギャラリーとカメラの選択肢を表示する
2. When ユーザーが画像を選択する, the Mobile App shall 画像をリサイズ（最大1024x1024ピクセル）し、圧縮する
3. When ユーザーが投稿ボタンをタップする, the Mobile App shall バックエンドAPIの署名付きURL取得エンドポイントを呼び出す
4. When 署名付きURLの取得に成功する, the Mobile App shall そのURLを使用してGoogle Cloud Storageに画像をアップロードする
5. When 画像のアップロードに成功する, the Mobile App shall アップロードされた画像のURLを取得し、投稿データに含める
6. While 画像をアップロード中である, the Mobile App shall アップロード進捗を表示する
7. If 画像のアップロードに失敗する, then the Mobile App shall エラーメッセージを表示し、ユーザーが再試行できるようにする
8. The Mobile App shall 対応画像形式をJPEG・PNG・GIFに制限し、ファイルサイズ上限を10MBとする

