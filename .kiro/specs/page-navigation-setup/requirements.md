# Requirements Document

## Introduction

本仕様は、「みんなの選手権」Flutterモバイルアプリにおける画面遷移構造の定義と、各ページ用の空ファイル作成を行うものである。app-requirements.mdに定義された画面構成（ホーム画面、選手権詳細画面、回答詳細画面、選手権作成画面、回答投稿/編集画面、マイページ）に基づき、go_routerを使用したルーティング構造を構築し、適切なディレクトリ構造でページファイルを配置する。

## Requirements

### Requirement 1: ルーティング構造の定義

**Objective:** As a 開発者, I want アプリ全体のルーティング構造が明確に定義されていること, so that 画面遷移の実装がスムーズに行えて、コードの保守性が向上する

#### Acceptance Criteria
1. The Mobile App shall ルートパスとして以下の画面を定義する: ホーム画面(`/`)、選手権詳細画面(`/championships/:id`)、回答詳細画面(`/championships/:championshipId/answers/:answerId`)、選手権作成画面(`/championships/create`)、回答投稿画面(`/championships/:id/answers/create`)、回答編集画面(`/championships/:championshipId/answers/:answerId/edit`)、マイページ(`/profile`)、プロフィール編集画面(`/profile/edit`)、ユーザー詳細画面(`/users/:id`)
2. The Mobile App shall go_routerパッケージを使用してルーティングを管理する
3. The Mobile App shall ルーターの設定を`lib/app/router.dart`に集約する

### Requirement 2: 画面ファイルの配置構造

**Objective:** As a 開発者, I want 各画面のファイルが機能別ディレクトリに整理されていること, so that コードの見通しがよく、機能追加や修正が容易になる

#### Acceptance Criteria
1. The Mobile App shall 以下のディレクトリ構造で画面ファイルを配置する: `lib/features/championship/presentation/pages/`、`lib/features/answer/presentation/pages/`、`lib/features/user/presentation/pages/`、`lib/features/auth/presentation/pages/`
2. The Mobile App shall 各ページファイルをStatelessWidgetまたはConsumerWidgetの形式で作成する
3. The Mobile App shall ページファイル名はスネークケース（例: `home_page.dart`）で命名する

### Requirement 3: ホーム画面の空ファイル作成

**Objective:** As a ユーザー, I want アプリ起動時にホーム画面が表示されること, so that 選手権一覧を閲覧できる

#### Acceptance Criteria
1. The Mobile App shall `lib/features/championship/presentation/pages/home_page.dart`に空のホーム画面ウィジェットを作成する
2. When アプリが起動した時, the Mobile App shall ホーム画面をデフォルトで表示する
3. The Mobile App shall ホーム画面に「選手権一覧」のプレースホルダーテキストを表示する

### Requirement 4: 選手権関連画面の空ファイル作成

**Objective:** As a ユーザー, I want 選手権の詳細確認と作成ができること, so that 選手権への参加や主催ができる

#### Acceptance Criteria
1. The Mobile App shall `lib/features/championship/presentation/pages/championship_detail_page.dart`に空の選手権詳細画面ウィジェットを作成する
2. The Mobile App shall `lib/features/championship/presentation/pages/championship_create_page.dart`に空の選手権作成画面ウィジェットを作成する
3. When 選手権詳細画面にアクセスした時, the Mobile App shall 選手権IDをパラメータとして受け取る

### Requirement 5: 回答関連画面の空ファイル作成

**Objective:** As a ユーザー, I want 回答の詳細確認、投稿、編集ができること, so that 選手権に参加できる

#### Acceptance Criteria
1. The Mobile App shall `lib/features/answer/presentation/pages/answer_detail_page.dart`に空の回答詳細画面ウィジェットを作成する
2. The Mobile App shall `lib/features/answer/presentation/pages/answer_create_page.dart`に空の回答投稿画面ウィジェットを作成する
3. The Mobile App shall `lib/features/answer/presentation/pages/answer_edit_page.dart`に空の回答編集画面ウィジェットを作成する
4. When 回答関連画面にアクセスした時, the Mobile App shall 必要なID（選手権ID、回答ID）をパラメータとして受け取る

### Requirement 6: ユーザー関連画面の空ファイル作成

**Objective:** As a ユーザー, I want 自分や他のユーザーのプロフィールを確認・編集できること, so that プラットフォーム上での自己表現やユーザー確認ができる

#### Acceptance Criteria
1. The Mobile App shall `lib/features/user/presentation/pages/profile_page.dart`に空のマイページウィジェットを作成する
2. The Mobile App shall `lib/features/user/presentation/pages/profile_edit_page.dart`に空のプロフィール編集画面ウィジェットを作成する
3. The Mobile App shall `lib/features/user/presentation/pages/user_detail_page.dart`に空のユーザー詳細画面ウィジェットを作成する
4. When ユーザー詳細画面にアクセスした時, the Mobile App shall ユーザーIDをパラメータとして受け取る

### Requirement 7: ナビゲーション構造の一貫性

**Objective:** As a ユーザー, I want 画面間の遷移が一貫していること, so that アプリの操作に迷わない

#### Acceptance Criteria
1. The Mobile App shall 全ての画面で戻るボタン（または戻るジェスチャー）をサポートする
2. The Mobile App shall ルートパス（`/`）以外の画面ではAppBarに戻るボタンを表示する
3. When ディープリンクでアクセスした時, the Mobile App shall 適切な画面を表示する

### Requirement 8: ボトムナビゲーションの構造

**Objective:** As a ユーザー, I want 主要な機能にすぐにアクセスできること, so that アプリの操作が快適になる

#### Acceptance Criteria
1. The Mobile App shall ボトムナビゲーションバーに「ホーム」と「マイページ」のタブを表示する
2. When ボトムナビゲーションのタブをタップした時, the Mobile App shall 対応する画面に遷移する
3. The Mobile App shall 現在選択中のタブをハイライト表示する
