# Implementation Plan

## Task Overview

本実装計画は、「みんなの選手権」Flutterモバイルアプリのナビゲーション基盤を構築する。mobileディレクトリへのFlutterプロジェクト作成、go_routerを使用したルーティング設定、機能別ディレクトリ構造での空ページファイル配置を行う。

---

## Tasks

- [x] 1. Flutterプロジェクトの初期化と依存関係の設定
- [x] 1.1 mobileディレクトリにFlutterプロジェクトを作成する
  - Flutter CLIを使用してmobileディレクトリに新規プロジェクトを作成
  - プロジェクト名は「minna_senshuken」とする
  - 最小SDKバージョンをFlutter 3.24以上に設定
  - 不要なサンプルコードを削除し、クリーンな状態にする
  - _Requirements: 2.1_

- [x] 1.2 go_routerおよびRiverpodの依存関係を追加する
  - pubspec.yamlにgo_router ^14.0.0を追加
  - pubspec.yamlにflutter_riverpod ^2.5.0を追加
  - flutter pub getで依存関係をインストール
  - analysis_options.yamlで推奨リントルールを設定
  - _Requirements: 1.2_

- [x] 2. 機能別ディレクトリ構造の作成
- [x] 2.1 (P) championshipドメインのディレクトリ構造を作成する
  - lib/features/championship/presentation/pages/ディレクトリを作成
  - 将来の拡張に備えてpresentation層の構造を整備
  - _Requirements: 2.1_

- [x] 2.2 (P) answerドメインのディレクトリ構造を作成する
  - lib/features/answer/presentation/pages/ディレクトリを作成
  - 将来の拡張に備えてpresentation層の構造を整備
  - _Requirements: 2.1_

- [x] 2.3 (P) userドメインのディレクトリ構造を作成する
  - lib/features/user/presentation/pages/ディレクトリを作成
  - 将来の拡張に備えてpresentation層の構造を整備
  - _Requirements: 2.1_

- [x] 2.4 (P) authドメインのディレクトリ構造を作成する
  - lib/features/auth/presentation/pages/ディレクトリを作成
  - 認証関連画面の将来実装に備える
  - _Requirements: 2.1_

- [x] 3. 選手権関連ページの空ファイル作成
- [x] 3.1 (P) ホーム画面のウィジェットを作成する
  - home_page.dartファイルを作成
  - StatelessWidgetとして「選手権一覧」プレースホルダーを表示
  - 画面中央にテキストを配置するシンプルなレイアウト
  - _Requirements: 3.1, 3.3_

- [x] 3.2 (P) 選手権詳細画面のウィジェットを作成する
  - championship_detail_page.dartファイルを作成
  - 選手権IDを必須パラメータとして受け取るウィジェット
  - プレースホルダーとして受け取ったIDを表示
  - _Requirements: 4.1, 4.3_

- [x] 3.3 (P) 選手権作成画面のウィジェットを作成する
  - championship_create_page.dartファイルを作成
  - フルスクリーン表示用のシンプルなプレースホルダーUI
  - AppBarに閉じるボタンを配置
  - _Requirements: 4.2_

- [x] 4. 回答関連ページの空ファイル作成
- [x] 4.1 (P) 回答詳細画面のウィジェットを作成する
  - answer_detail_page.dartファイルを作成
  - 選手権IDと回答IDを必須パラメータとして受け取るウィジェット
  - プレースホルダーとして受け取ったIDを表示
  - _Requirements: 5.1, 5.4_

- [x] 4.2 (P) 回答投稿画面のウィジェットを作成する
  - answer_create_page.dartファイルを作成
  - 選手権IDを必須パラメータとして受け取るウィジェット
  - フルスクリーン表示用のプレースホルダーUI
  - _Requirements: 5.2, 5.4_

- [x] 4.3 (P) 回答編集画面のウィジェットを作成する
  - answer_edit_page.dartファイルを作成
  - 選手権IDと回答IDを必須パラメータとして受け取るウィジェット
  - フルスクリーン表示用のプレースホルダーUI
  - _Requirements: 5.3, 5.4_

- [x] 5. ユーザー関連ページの空ファイル作成
- [x] 5.1 (P) マイページ画面のウィジェットを作成する
  - profile_page.dartファイルを作成
  - StatelessWidgetとして「マイページ」プレースホルダーを表示
  - ボトムナビゲーションのタブとして使用される
  - _Requirements: 6.1_

- [x] 5.2 (P) プロフィール編集画面のウィジェットを作成する
  - profile_edit_page.dartファイルを作成
  - フルスクリーン表示用のプレースホルダーUI
  - AppBarに閉じるボタンを配置
  - _Requirements: 6.2_

- [x] 5.3 (P) ユーザー詳細画面のウィジェットを作成する
  - user_detail_page.dartファイルを作成
  - ユーザーIDを必須パラメータとして受け取るウィジェット
  - プレースホルダーとして受け取ったIDを表示
  - _Requirements: 6.3, 6.4_

- [x] 6. ボトムナビゲーションシェルの実装
- [x] 6.1 MainShellウィジェットを作成する
  - main_shell.dartファイルをlib/app/に作成
  - StatefulNavigationShellを受け取るウィジェット
  - NavigationBarで「ホーム」と「マイページ」タブを表示
  - タブ切り替え時にgoBranchで遷移
  - 選択中タブのハイライト表示を実装
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 7. ルーター設定の実装
- [x] 7.1 GoRouterの基本設定を作成する
  - router.dartファイルをlib/app/に作成
  - rootNavigatorKeyの定義
  - initialLocationを「/」に設定
  - StatefulShellRoute.indexedStackの構造を定義
  - _Requirements: 1.2, 1.3_

- [x] 7.2 ホームブランチのルートを設定する
  - ホーム画面（/）をルートとして設定
  - 選手権詳細画面（/championships/:id）をネストルートとして追加
  - 回答詳細画面をさらにネストして追加
  - ユーザー詳細画面（/users/:id）をネストルートとして追加
  - pathParametersから各IDを取得してページに渡す
  - _Requirements: 1.1, 3.2, 4.3, 5.4, 6.4, 7.3_

- [x] 7.3 プロファイルブランチのルートを設定する
  - マイページ（/profile）をルートとして設定
  - StatefulShellBranchとして独立した状態管理
  - _Requirements: 1.1_

- [x] 7.4 シェル外ルートを設定する
  - 選手権作成画面（/championships/create）をparentNavigatorKeyで設定
  - 回答投稿画面をparentNavigatorKeyで設定
  - 回答編集画面をparentNavigatorKeyで設定
  - プロフィール編集画面（/profile/edit）をparentNavigatorKeyで設定
  - _Requirements: 1.1, 7.1, 7.2_

- [x] 8. アプリケーションのエントリーポイント統合
- [x] 8.1 main.dartでルーターを統合する
  - MaterialApp.routerを使用してGoRouterを設定
  - ProviderScopeでRiverpodを有効化
  - アプリのテーマ設定（Material 3ベース）
  - 日本語ローカライゼーションの基本設定
  - _Requirements: 3.2_

- [x] 8.2 アプリ全体の動作確認を行う
  - flutter runでアプリを起動して動作確認
  - ボトムナビゲーションのタブ切り替えを確認
  - 各画面への遷移とプレースホルダー表示を確認
  - 戻るボタンとジェスチャーの動作を確認
  - _Requirements: 7.1, 7.2, 8.1, 8.2, 8.3_

---

## Requirements Coverage Matrix

| Requirement | Tasks |
|-------------|-------|
| 1.1 | 7.2, 7.3, 7.4 |
| 1.2 | 1.2, 7.1 |
| 1.3 | 7.1 |
| 2.1 | 1.1, 2.1, 2.2, 2.3, 2.4 |
| 2.2 | 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3 |
| 2.3 | 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3 |
| 3.1 | 3.1 |
| 3.2 | 8.1 |
| 3.3 | 3.1 |
| 4.1 | 3.2 |
| 4.2 | 3.3 |
| 4.3 | 3.2, 7.2 |
| 5.1 | 4.1 |
| 5.2 | 4.2 |
| 5.3 | 4.3 |
| 5.4 | 4.1, 4.2, 4.3, 7.2 |
| 6.1 | 5.1 |
| 6.2 | 5.2 |
| 6.3 | 5.3 |
| 6.4 | 5.3, 7.2 |
| 7.1 | 7.4, 8.2 |
| 7.2 | 7.4, 8.2 |
| 7.3 | 7.2 |
| 8.1 | 6.1, 8.2 |
| 8.2 | 6.1, 8.2 |
| 8.3 | 6.1, 8.2 |
