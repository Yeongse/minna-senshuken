# モバイルクライアント実装タスク

## タスク概要

本実装計画は、「みんなの選手権」モバイルアプリケーションの完全な機能実装を段階的に行うためのタスク分解である。既存のAPI基盤（ApiClient, AuthService, ErrorInterceptor, UploadService）を維持しつつ、未実装のビジネスロジック、状態管理、UIコンポーネントを追加する。

**実装方針**: ハイブリッドアプローチ（Phase 1: 既存コード拡張、Phase 2: リファクタリング）

## タスク一覧

### 1. 基盤機能の実装

- [x] 1.1 (P) 依存関係の追加とネイティブ設定
  - `pubspec.yaml`に新規パッケージを追加（image_picker 1.0.7, flutter_image_compress 2.1.0, connectivity_plus 5.0.2）
  - iOS: Info.plistにカメラ・ギャラリーアクセス権限を追加（NSPhotoLibraryUsageDescription, NSCameraUsageDescription）
  - Android: AndroidManifest.xmlにREAD_EXTERNAL_STORAGE, CAMERA権限を追加
  - flutter pub getでパッケージをインストール
  - _Requirements: 12.1, 12.2_

- [x] 1.2 (P) キャッシュサービスの実装
  - `core/services/cache_service.dart`を新規作成
  - CacheServiceInterfaceを定義（set, get, remove, clear メソッド）
  - CacheServiceクラスでStorageServiceを利用したTTL管理を実装
  - キャッシュキー生成メソッド（championshipListKey, championshipDetailKey, userProfileKey）を実装
  - get時にタイムスタンプを比較してTTL超過判定
  - `core/providers.dart`にcacheServiceProviderを追加
  - _Requirements: 11.1, 11.5_

- [x] 1.3 (P) 画像選択・圧縮ヘルパーの実装
  - `core/utils/image_helper.dart`を新規作成
  - ImageHelperクラスでpickAndCompressImageメソッドを実装
  - ImagePicker.pickImageでギャラリー/カメラから画像選択
  - ファイルサイズ10MB超過チェック（FileTooLargeExceptionをスロー）
  - FlutterImageCompress.compressAndGetFileで1024x1024px、品質85%に圧縮
  - 圧縮済みFileまたはnull（キャンセル時）を返す
  - _Requirements: 12.1, 12.2, 12.8_

- [x] 1.4 (P) エラー表示・ローディングウィジェットの実装
  - `core/widgets/error_view.dart`を新規作成してErrorViewウィジェットを実装
  - ApiExceptionからエラーメッセージを抽出し、エラーアイコン・メッセージ・再試行ボタンを表示
  - `core/widgets/loading_view.dart`を新規作成してLoadingViewウィジェットを実装
  - Center + CircularProgressIndicatorでローディング状態を表示
  - _Requirements: 10.3, 10.4, 10.5, 10.6_

- [x] 1.5 (P) ネットワーク状態監視の実装
  - `core/providers.dart`にconnectivityProviderを追加（StreamProvider<ConnectivityResult>）
  - connectivity_plusパッケージのConnectivity().onConnectivityChangedをStreamで監視
  - オフライン→オンライン遷移時にref.invalidateで各Providerを無効化
  - _Requirements: 11.2, 11.3_

### 2. 認証機能の実装

- [x] 2.1 サインイン画面の実装
  - `features/auth/presentation/pages/sign_in_page.dart`を新規作成
  - TextFormFieldでメール・パスワード入力フォームを実装
  - Flutter Formバリデーション（メール形式チェック、パスワード6文字以上）
  - サインインボタンタップでAuthService.signInWithEmailAndPasswordを呼び出し
  - 成功時にGoRouter.go('/')でホーム画面に遷移
  - FirebaseAuthException.codeをswitch文で日本語エラーメッセージに変換
  - ローカル状態（isLoading, errorMessage）でローディング状態とエラーメッセージを管理
  - _Requirements: 1.1, 1.2_

- [x] 2.2 AuthServiceへのサインインメソッド追加
  - 既存の`core/auth/auth_service.dart`にsignInWithEmailAndPasswordメソッドを追加
  - FirebaseAuth.instance.signInWithEmailAndPasswordを呼び出し
  - 成功時にUserCredentialを返す
  - _Requirements: 1.2_

- [x] 2.3 ログイン状態復元とリダイレクト設定
  - `app/router.dart`のGoRouterにredirectロジックを追加
  - authStateProvider.whenでログイン状態を監視
  - 未ログインで保護ルートにアクセス時、'/sign-in'にリダイレクト
  - ログイン済みで'/sign-in'にアクセス時、'/'にリダイレクト
  - _Requirements: 1.6_

### 3. 選手権機能の実装

- [x] 3.1 選手権一覧の状態管理実装
  - `core/providers.dart`にchampionshipListNotifierProviderを追加（StateNotifierProvider）
  - ChampionshipListNotifierクラスでAsyncValue<List<Championship>>を管理
  - ChampionshipApi.getChampionshipsを呼び出して選手権一覧を取得
  - CacheService.setで5分間キャッシュ
  - ステータスフィルタ（status: ChampionshipStatus?）をパラメータで受け取る
  - ネットワークエラー時はCacheService.getからキャッシュを取得
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 11.2, 11.4_

- [x] 3.2 ホーム画面（選手権一覧）のUI実装
  - 既存の`features/championship/presentation/pages/home_page.dart`をConsumerWidgetに変更
  - TabBarでステータス別タブ（募集中/選考中/発表済み）を実装
  - championshipListNotifierProvider.whenでローディング・エラー・データ表示を切り替え
  - ListView.builderで選手権カードを表示（タイトル、説明、ステータス、開始日、終了日、主催者情報）
  - RefreshIndicatorでPull-to-Refresh実装（ref.refresh）
  - 選手権カードタップでGoRouter.go('/championships/$id')で詳細画面に遷移
  - _Requirements: 2.1, 2.2, 2.5, 2.6, 2.7_

- [x] 3.3 選手権詳細の状態管理実装
  - `core/providers.dart`にchampionshipDetailProviderを追加（FutureProvider）
  - ChampionshipApi.getChampionshipByIdを呼び出して選手権詳細を取得
  - CacheService.setで10分間キャッシュ
  - answerListProviderを追加（FutureProvider）
  - AnswerApi.getAnswersByChampionshipIdを呼び出して回答一覧を取得
  - _Requirements: 3.1, 3.2, 11.4_

- [x] 3.4 選手権詳細画面のUI実装
  - 既存の`features/championship/presentation/pages/championship_detail_page.dart`をConsumerWidgetに変更
  - championshipDetailProvider.whenで選手権詳細を表示（タイトル、説明、ステータス、主催者、総括コメント）
  - answerListProvider.whenで回答一覧を表示（テキスト、画像、いいね数、コメント数、受賞情報）
  - ステータスがRECRUITINGの場合、「回答を投稿」ボタンを表示
  - 「回答を投稿」ボタンタップでGoRouter.go('/championships/$id/answers/create')に遷移
  - 回答カードタップでGoRouter.go('/answers/$answerId')で回答詳細画面に遷移
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [x] 3.5 選手権作成の状態管理実装
  - `core/providers.dart`にchampionshipCreateNotifierProviderを追加（StateNotifierProvider）
  - ChampionshipCreateNotifierクラスでAsyncValue<Championship?>を管理
  - createメソッドでバリデーション（title: 1-50文字、description: 1-500文字、durationDays: 1-14日）
  - ChampionshipApi.createChampionshipを呼び出し
  - 成功時にAsyncValue.dataをセット、失敗時にAsyncValue.errorをセット
  - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.6, 4.7_

- [x] 3.6 選手権作成画面のUI実装
  - 既存の`features/championship/presentation/pages/championship_create_page.dart`をConsumerWidgetに変更
  - TextFormFieldでtitle, description, durationDaysを入力
  - Flutter Formバリデーションでエラーメッセージを表示
  - 作成ボタンタップでchampionshipCreateNotifier.createを呼び出し
  - championshipCreateNotifierProvider.whenでローディング中はボタン無効化
  - 成功時にGoRouter.go('/')でホーム画面に遷移、SnackBarで成功メッセージ表示
  - エラー時にSnackBarでエラーメッセージ表示
  - _Requirements: 4.1, 4.2, 4.3, 4.8_

### 4. 回答機能の実装

- [x] 4.1 回答詳細の状態管理実装
  - `core/providers.dart`にanswerDetailProviderを追加（FutureProvider）
  - AnswerApi.getAnswerByIdを呼び出して回答詳細を取得
  - commentListProviderを追加（FutureProvider）
  - AnswerApi.getCommentsByAnswerIdを呼び出してコメント一覧を取得
  - _Requirements: 5.1, 5.2, 5.4_

- [x] 4.2 回答詳細画面のUI実装
  - 既存の`features/answer/presentation/pages/answer_detail_page.dart`をConsumerWidgetに変更
  - answerDetailProvider.whenで回答詳細を表示（テキスト、画像、投稿者、いいね数、コメント数、受賞情報）
  - commentListProvider.whenでコメント一覧を表示（テキスト、投稿者、投稿日時）
  - ログイン済みの場合、いいねボタンとコメント入力欄を表示
  - いいねボタンタップでAnswerApi.addLikeを呼び出し、ref.invalidate(answerDetailProvider)で再取得
  - コメント送信ボタンタップでAnswerApi.createCommentを呼び出し、ref.invalidate(commentListProvider)で再取得
  - コメントテキスト1-200文字のバリデーション
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9_

- [x] 4.3 回答作成の状態管理実装
  - `core/providers.dart`にanswerCreateNotifierProviderを追加（StateNotifierProvider）
  - AnswerCreateNotifierクラスでAsyncValue<Answer?>とuploadProgress: double?を管理
  - setImageメソッドでimageFileを設定
  - createメソッドでバリデーション（text: 1-300文字）
  - imageFileがある場合、UploadService.uploadImageを呼び出して画像をアップロード（onProgressでuploadProgressを更新）
  - AnswerApi.createAnswerを呼び出し（text, imageUrl）
  - 成功時にAsyncValue.dataをセット、失敗時にAsyncValue.errorをセット
  - _Requirements: 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 12.3, 12.4, 12.5, 12.6, 12.7_

- [x] 4.4 回答作成画面のUI実装
  - 既存の`features/answer/presentation/pages/answer_create_page.dart`をConsumerWidgetに変更
  - 選手権のタイトル・説明を表示
  - TextFormFieldでtextを入力
  - 画像選択ボタンタップでImageHelper.pickAndCompressImageを呼び出し
  - 画像選択後、answerCreateNotifier.setImageを呼び出し、プレビューを表示
  - 投稿ボタンタップでanswerCreateNotifier.createを呼び出し
  - answerCreateNotifierProvider.whenでローディング中はボタン無効化、uploadProgressでプログレスバー表示
  - 成功時にGoRouter.go('/championships/$championshipId')で選手権詳細画面に遷移、SnackBar表示
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 12.6_

- [x] 4.5 回答編集の状態管理実装
  - `core/providers.dart`にanswerEditNotifierProviderを追加（StateNotifierProvider）
  - AnswerEditNotifierクラスでAsyncValue<Answer?>を管理
  - initメソッドで既存回答データを取得、権限チェック（answer.userId == currentUser.id）
  - setImageメソッドでimageFileを設定
  - updateメソッドでバリデーション（text: 1-300文字）
  - imageFileがある場合、UploadService.uploadImageを呼び出し
  - AnswerApi.updateAnswerを呼び出し（text, imageUrl）
  - 成功時にAsyncValue.dataをセット、失敗時にAsyncValue.errorをセット
  - _Requirements: 7.1, 7.2, 7.4, 7.5, 7.6, 7.7, 7.8_

- [x] 4.6 回答編集画面のUI実装
  - 既存の`features/answer/presentation/pages/answer_edit_page.dart`をConsumerWidgetに変更
  - answerEditNotifier.initで既存回答データを取得
  - TextFormFieldでtextを編集フォームに表示
  - 既存画像がある場合、プレビューを表示
  - 画像選択ボタンタップでImageHelper.pickAndCompressImageを呼び出し、answerEditNotifier.setImageで設定
  - 更新ボタンタップでanswerEditNotifier.updateを呼び出し
  - answerEditNotifierProvider.whenでローディング中はボタン無効化
  - 成功時にGoRouter.go('/answers/$answerId')で回答詳細画面に遷移、SnackBar表示
  - _Requirements: 7.1, 7.2, 7.3, 7.5, 7.6_

### 5. ユーザー機能の実装

- [x] 5.1 プロフィール表示の状態管理実装
  - `core/providers.dart`にprofileProviderを追加（FutureProvider）
  - currentUserProviderからFirebase UIDを取得
  - UserApi.getUserByIdを呼び出してユーザー情報を取得
  - CacheService.setで10分間キャッシュ
  - _Requirements: 8.1, 11.4_

- [x] 5.2 プロフィール画面のUI実装
  - 既存の`features/user/presentation/pages/profile_page.dart`をConsumerWidgetに変更
  - profileProvider.whenでユーザー情報を表示（displayName, avatarUrl, bio, twitterUrl）
  - 編集ボタンタップでGoRouter.go('/profile/edit')に遷移
  - ログアウトボタンタップでAuthService.signOutを呼び出し
  - ログアウト後、GoRouter redirectでサインイン画面に自動遷移
  - _Requirements: 8.1, 8.2, 1.3_

- [x] 5.3 プロフィール編集の状態管理実装
  - `core/providers.dart`にprofileEditNotifierProviderを追加（StateNotifierProvider）
  - ProfileEditNotifierクラスでAsyncValue<User?>を管理
  - setAvatarメソッドでavatarFileを設定
  - updateメソッドでバリデーション（displayName: 1-30文字、bio: 0-200文字）
  - avatarFileがある場合、UploadService.uploadImageを呼び出し
  - UserApi.updateProfileを呼び出し（displayName, bio, avatarUrl, twitterUrl）
  - 成功時にAsyncValue.dataをセット、失敗時にAsyncValue.errorをセット
  - _Requirements: 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10_

- [x] 5.4 プロフィール編集画面のUI実装
  - 既存の`features/user/presentation/pages/profile_edit_page.dart`をConsumerWidgetに変更
  - TextFormFieldでdisplayName, bio, twitterUrlを入力
  - Flutter Formバリデーションでエラーメッセージを表示
  - アバター画像選択ボタンタップでImageHelper.pickAndCompressImageを呼び出し、profileEditNotifier.setAvatarで設定
  - 保存ボタンタップでprofileEditNotifier.updateを呼び出し
  - profileEditNotifierProvider.whenでローディング中はボタン無効化
  - 成功時にGoRouter.go('/profile')でプロフィール画面に遷移、SnackBar表示
  - _Requirements: 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9_

- [x] 5.5 (P) ユーザー詳細表示の状態管理実装
  - `core/providers.dart`にuserDetailProviderを追加（FutureProvider）
  - UserApi.getUserByIdを呼び出してユーザー情報を取得
  - userChampionshipsProviderを追加（FutureProvider）
  - UserApi.getUserChampionshipsを呼び出して主催選手権一覧を取得
  - userAnswersProviderを追加（FutureProvider）
  - UserApi.getUserAnswersを呼び出して回答一覧を取得
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 5.6 (P) ユーザー詳細画面のUI実装
  - 既存の`features/user/presentation/pages/user_detail_page.dart`をConsumerWidgetに変更
  - userDetailProvider.whenでユーザー情報を表示（displayName, avatarUrl, bio, twitterUrl）
  - TabBarで主催選手権タブ・回答タブを実装
  - userChampionshipsProvider.whenで主催選手権一覧を表示
  - userAnswersProvider.whenで回答一覧を表示
  - ListView.builderで各一覧を表示
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

### 6. エラーハンドリング・状態管理の統合

- [x] 6.1 ErrorInterceptorの401エラー自動ログアウト実装
  - 既存の`core/api/error_interceptor.dart`を修正
  - HTTP 401エラー検知時、UnauthorizedExceptionまたはTOKEN_EXPIREDエラーコードの場合、AuthService.signOutを呼び出し
  - ログアウト後、GoRouter.go('/sign-in')でサインイン画面に遷移
  - _Requirements: 10.3_

- [x] 6.2 API エラーハンドリングのUI統合
  - 全画面でAsyncValue.whenのerrorブランチでErrorViewウィジェットを使用
  - HTTP 400エラー時、ClientException.detailsからバリデーションエラーを抽出してTextFormField.errorTextに表示
  - HTTP 500エラー時、「サーバーエラーが発生しました。しばらくしてから再度お試しください」を表示
  - ネットワークエラー時、「インターネット接続を確認してください」を表示
  - _Requirements: 10.4, 10.5, 10.6_

### 7. 統合テストとエンドツーエンド動作確認

- [x] 7.1 認証フローのE2E確認
  - サインイン画面でメール/パスワード入力→サインイン成功→ホーム画面遷移を手動確認
  - ログアウトボタンタップ→サインイン画面遷移を手動確認
  - 未ログイン時の保護ルートアクセス→サインイン画面リダイレクトを確認
  - トークン期限切れ時の自動リフレッシュ動作を確認（ErrorInterceptor）
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 7.2 選手権機能のE2E確認
  - ホーム画面でタブ切り替え→ステータス別一覧表示を確認
  - Pull-to-Refresh→一覧再取得を確認
  - 選手権カードタップ→詳細画面遷移→回答一覧表示を確認
  - 選手権作成フォーム入力→API呼び出し→ホーム画面リフレッシュを確認
  - バリデーションエラー表示を確認（title長すぎる、descriptionなし等）
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8_

- [x] 7.3 回答機能のE2E確認
  - 回答作成画面で画像選択→プレビュー表示→投稿→詳細画面遷移を確認
  - 画像アップロード進捗表示を確認
  - 回答編集画面で既存データ表示→編集→更新→詳細画面遷移を確認
  - いいねボタンタップ→いいね数増加を確認
  - コメント投稿→コメント一覧更新を確認
  - 他ユーザーの回答編集不可を確認（権限チェック）
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8_

- [x] 7.4 ユーザー機能のE2E確認
  - プロフィール画面でユーザー情報表示→編集ボタン→編集画面遷移を確認
  - プロフィール編集画面でアバター画像選択→保存→プロフィール画面リフレッシュを確認
  - ユーザー詳細画面でユーザー情報・投稿一覧表示を確認
  - タブ切り替え（主催選手権/回答）を確認
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 7.5 オフライン対応のE2E確認
  - ネットワーク切断→画面表示→キャッシュからデータ表示を確認
  - オフラインバナー表示を確認
  - ネットワーク復帰→自動リフレッシュ→最新データ表示を確認
  - キャッシュTTL超過時の期限切れ警告を確認
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 7.6 エラーハンドリングのE2E確認
  - 各画面でネットワークエラー→エラーメッセージ・再試行ボタン表示を確認
  - バリデーションエラー→フィールド別エラーメッセージ表示を確認
  - 401エラー→自動ログアウト→サインイン画面遷移を確認
  - 500エラー→サーバーエラーメッセージ表示を確認
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

## 要件カバレッジ確認

### 全要件のマッピング

- **Requirement 1 (認証機能)**: タスク 2.1, 2.2, 2.3, 6.1, 7.1
- **Requirement 2 (選手権一覧表示)**: タスク 3.1, 3.2, 7.2
- **Requirement 3 (選手権詳細表示)**: タスク 3.3, 3.4, 7.2
- **Requirement 4 (選手権作成)**: タスク 3.5, 3.6, 7.2
- **Requirement 5 (回答詳細表示)**: タスク 4.1, 4.2, 7.3
- **Requirement 6 (回答作成)**: タスク 4.3, 4.4, 7.3
- **Requirement 7 (回答編集)**: タスク 4.5, 4.6, 7.3
- **Requirement 8 (プロフィール表示・編集)**: タスク 5.1, 5.2, 5.3, 5.4, 7.4
- **Requirement 9 (ユーザー詳細表示)**: タスク 5.5, 5.6, 7.4
- **Requirement 10 (エラーハンドリング・状態管理)**: タスク 1.4, 6.1, 6.2, 7.6
- **Requirement 11 (オフライン対応・キャッシング)**: タスク 1.2, 1.5, 3.1, 3.3, 5.1, 7.5
- **Requirement 12 (画像アップロード)**: タスク 1.1, 1.3, 4.3, 7.3

### 意図的に延期された要件

なし（全要件を実装タスクに含めている）

## タスク実行順序とパラレル実行

### Phase 1: 基盤機能（並列実行可能）
- タスク 1.1, 1.2, 1.3, 1.4, 1.5 は依存関係がないため、並列実行可能

### Phase 2: 認証機能（順次実行）
- タスク 2.1 → 2.2 → 2.3 の順序で実行

### Phase 3: 選手権・回答・ユーザー機能（部分的に並列実行可能）
- タスク 3.1-3.6（選手権）、4.1-4.6（回答）、5.1-5.6（ユーザー）は互いに独立しているが、各機能内では順次実行
- 5.5, 5.6 はユーザー詳細機能で、5.1-5.4と並列実行可能

### Phase 4: 統合テスト（順次実行）
- タスク 6.1 → 6.2 → 7.1 → 7.2 → 7.3 → 7.4 → 7.5 → 7.6 の順序で実行

## 次のステップ

タスクを確認後、以下のコマンドで実装を開始してください：

```bash
# 特定タスクの実装
/kiro:spec-impl mobile-client 1.1

# 複数タスクの実装（推奨: コンテキストをクリアしてから次のタスクに進む）
/kiro:spec-impl mobile-client 1.1,1.2

# 全タスクの実装（非推奨: コンテキスト肥大化のリスク）
/kiro:spec-impl mobile-client
```

**重要**: タスク間でコンテキストをクリアして、クリーンな状態で次のタスクに進むことを推奨します。
