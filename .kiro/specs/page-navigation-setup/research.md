# Research & Design Decisions

## Summary
- **Feature**: `page-navigation-setup`
- **Discovery Scope**: Simple Addition（グリーンフィールドでの基本的なルーティング構造とページファイル作成）
- **Key Findings**:
  - go_router v14.x で StatefulShellRoute.indexedStack を使用したボトムナビゲーションが推奨
  - 各タブのナビゲーション状態を独立して保持可能
  - parentNavigatorKey を使用してシェル外のルートを管理可能

## Research Log

### go_router StatefulShellRoute
- **Context**: ボトムナビゲーションとネストされたナビゲーション状態の保持方法を調査
- **Sources Consulted**:
  - [go_router | pub.dev](https://pub.dev/packages/go_router)
  - [StatefulShellRoute class](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html)
  - [Flutter公式 example](https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stateful_shell_route.dart)
- **Findings**:
  - `StatefulShellRoute.indexedStack` が IndexedStack を使用した実装に適している
  - 各 `StatefulShellBranch` が独自の Navigator を持ち、状態を保持
  - `navigationShell.goBranch(index)` でタブ間遷移
  - シェル外のルート（選手権作成など）は `parentNavigatorKey` を指定して親 Navigator に配置
- **Implications**: ホーム画面とマイページをそれぞれ StatefulShellBranch として定義し、詳細画面などは各ブランチのサブルートまたはシェル外ルートとして定義

### Flutter Clean Architecture ディレクトリ構造
- **Context**: 機能別ディレクトリ構造の設計
- **Sources Consulted**: README.md、app-requirements.md
- **Findings**:
  - `lib/features/[feature]/presentation/pages/` の構造が推奨
  - Riverpod を状態管理に使用予定
  - ConsumerWidget または ConsumerStatefulWidget をページで使用
- **Implications**: 各機能（championship, answer, user, auth）ごとにディレクトリを分離

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| StatefulShellRoute.indexedStack | IndexedStack ベースのボトムナビゲーション | 各タブの状態保持、公式推奨 | 初期は全タブをビルド | 本プロジェクトで採用 |
| ShellRoute + 手動状態管理 | 基本的な ShellRoute | シンプル | 状態保持が複雑 | 不採用 |

## Design Decisions

### Decision: StatefulShellRoute.indexedStack の採用
- **Context**: ホームとマイページのボトムナビゲーションで各タブの状態を保持する必要がある
- **Alternatives Considered**:
  1. ShellRoute + PageStorageKey による手動状態管理
  2. StatefulShellRoute.indexedStack（公式推奨）
- **Selected Approach**: StatefulShellRoute.indexedStack を使用
- **Rationale**: 公式推奨であり、各タブのナビゲーション状態が自動的に保持される
- **Trade-offs**: 初期ビルドで全タブがビルドされるが、ユーザー体験としてはシームレスな遷移が実現
- **Follow-up**: 実装時にメモリ使用量を監視

### Decision: ルートパス構造
- **Context**: app-requirements.md の画面構成に基づきURL構造を設計
- **Selected Approach**:
  - ホーム: `/`
  - 選手権詳細: `/championships/:id`
  - 選手権作成: `/championships/create`
  - 回答詳細: `/championships/:championshipId/answers/:answerId`
  - 回答投稿: `/championships/:id/answers/create`
  - 回答編集: `/championships/:championshipId/answers/:answerId/edit`
  - マイページ: `/profile`
  - プロフィール編集: `/profile/edit`
  - ユーザー詳細: `/users/:id`
- **Rationale**: RESTful なURL構造で、リソースの階層関係が明確

### Decision: シェル外ルートの分類
- **Context**: どの画面をボトムナビゲーション内に含め、どの画面を外に置くか
- **Selected Approach**:
  - シェル内（ボトムナビ表示）: ホーム、マイページ、選手権詳細、回答詳細、ユーザー詳細
  - シェル外（ボトムナビ非表示）: 選手権作成、回答投稿/編集、プロフィール編集
- **Rationale**: 作成・編集系はフルスクリーンで集中できるUIが望ましい

## Risks & Mitigations
- **Risk 1**: mobileディレクトリが未作成 → Flutterプロジェクト作成をタスクに含める
- **Risk 2**: 空ページファイルのみで動作確認できない可能性 → プレースホルダーUIを含める

## References
- [go_router | pub.dev](https://pub.dev/packages/go_router)
- [StatefulShellRoute Documentation](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html)
- [Flutter Bottom Navigation with go_router](https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter/)
