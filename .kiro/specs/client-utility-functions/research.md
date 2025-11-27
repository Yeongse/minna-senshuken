# Research & Design Decisions

## Summary
- **Feature**: `client-utility-functions`
- **Discovery Scope**: New Feature（グリーンフィールド - クライアント側のHTTP通信・認証・ユーティリティ基盤の新規構築）
- **Key Findings**:
  - Dioパッケージがインターセプター、リトライ、進捗通知など高度な機能を提供し、本プロジェクトの要件に適合
  - Firebase Auth SDKが自動トークンリフレッシュを提供するが、APIコール前の明示的なトークン取得が推奨
  - flutter_secure_storageがトークン等の機密データ保存に適切

## Research Log

### HTTPクライアントライブラリの選定
- **Context**: Flutter向けHTTPクライアントとして`http`パッケージと`dio`パッケージの比較検討
- **Sources Consulted**:
  - [Http vs Dio in Flutter: Which is the Best HTTP Client?](https://www.codemicros.com/2024/08/http-vs-dio-in-flutter-which-is-best.html)
  - [Dio vs HTTP in Flutter: A Practical, Clear Comparison](https://dev.to/heyroziq/dio-vs-http-in-flutter-a-practical-clear-comparison-2id8)
  - [Mastering HTTP Calls in Flutter (2025 Edition)](https://medium.com/@pv.jassim/mastering-http-calls-in-flutter-2025-edition-http-vs-dio-vs-retrofit-1962ec46be43)
- **Findings**:
  - `http`パッケージ: 軽量・シンプル、Dart公式、基本機能のみ、インターセプター非対応
  - `dio`パッケージ: 高機能、インターセプター対応、自動JSONデコード、ファイルアップロード進捗通知、リクエストキャンセル対応
  - 中〜大規模アプリケーションには`dio`が推奨
- **Implications**: 認証トークンの自動付与、エラーハンドリングの一元化、アップロード進捗通知など要件を満たすため`dio`を採用

### Firebase認証トークン管理
- **Context**: Firebase ID Tokenの取得・リフレッシュのベストプラクティス調査
- **Sources Consulted**:
  - [Firebase Authentication Token Expiration Handling](https://bootstrapped.app/guide/how-to-handle-firebase-authentication-token-expiration-in-a-flutter-app)
  - [Flutter best practices: ID token refresh](https://stackoverflow.com/questions/58523682/flutter-best-pracices-do-i-need-to-refresh-the-idtoken-every-time-i-make-an-htt)
  - [Using Firebase Authentication - FlutterFire](https://firebase.flutter.dev/docs/auth/usage/)
- **Findings**:
  - Firebase ID Tokenは1時間で期限切れ、Refresh Tokenで新規取得可能
  - `getIdToken()`は期限切れ時に自動リフレッシュ
  - `getIdToken(true)`で強制リフレッシュ可能
  - 毎リクエスト前の強制リフレッシュは非推奨（パフォーマンス低下）
  - `userChanges()`でトークン変更を監視可能
- **Implications**: Dioインターセプターで`getIdToken()`を呼び出し、401エラー時に`getIdToken(true)`で強制リフレッシュして再試行

### ローカルストレージの選定
- **Context**: トークン・設定データの永続化方法の検討
- **Sources Consulted**:
  - [Shared Preferences vs Flutter Secure Storage](https://medium.com/@dev.alababidy/using-flutter-secure-storage-vs-flutter-shared-preferences-b79c2f358fe8)
  - [flutter_secure_storage | pub.dev](https://pub.dev/packages/flutter_secure_storage)
  - [Flutter Official: Store key-value data on disk](https://docs.flutter.dev/cookbook/persistence/key-value)
- **Findings**:
  - `shared_preferences`: 非暗号化、シンプル、非機密データ向け
  - `flutter_secure_storage`: 暗号化（iOS: Keychain、Android: KeyStore+AES）、機密データ向け
  - Firebase Authは内部でセッション永続化を管理
- **Implications**: ユーザー設定には`shared_preferences`、将来的な機密データには`flutter_secure_storage`を検討。Firebase認証状態はSDKが管理するため別途トークン保存は不要

### バックエンドAPI構造の分析
- **Context**: 既存バックエンドAPIの仕様把握
- **Sources Consulted**: プロジェクト内部コード（`backend/src/routes/`、`backend/src/lib/`）
- **Findings**:
  - 認証: `Authorization: Bearer <Firebase ID Token>`
  - ページング: `page`(1〜)、`limit`(1〜100、デフォルト20)
  - エラーレスポンス: `{ error: { code, message, details? } }`
  - エラーコード: `UNAUTHORIZED`, `TOKEN_EXPIRED`, `VALIDATION_ERROR`, `NOT_FOUND`など
  - 成功レスポンス: 単一リソースまたは`{ items, pagination }`形式
- **Implications**: クライアント側でバックエンドのエラーコード体系に対応したエラークラスを定義

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Repository Pattern | データソースを抽象化し、ドメイン層から分離 | テスト容易性、データソース切り替え可能 | 小規模プロジェクトには過剰な場合あり | Flutter/Riverpod界隈で広く採用 |
| Service Layer Pattern | ビジネスロジックをサービスクラスに集約 | シンプル、直接的 | スケール時に肥大化の懸念 | ユーティリティ関数群に適合 |
| **採用**: Service Layer + Dio Interceptors | Dioインターセプターで横断的関心事を処理、サービスクラスでAPIエンドポイントをラップ | シンプルかつ拡張性あり | - | 本プロジェクトの規模に適切 |

## Design Decisions

### Decision: HTTPクライアントとしてDioを採用
- **Context**: 認証トークン自動付与、統一エラーハンドリング、アップロード進捗通知が必要
- **Alternatives Considered**:
  1. `http`パッケージ — シンプルだがインターセプター非対応
  2. `dio`パッケージ — 高機能、インターセプター対応
  3. `retrofit` + `dio` — 型安全だが設定が複雑
- **Selected Approach**: `dio`パッケージを直接使用
- **Rationale**: 必要な機能（インターセプター、進捗通知）を備え、設定がシンプル
- **Trade-offs**: パッケージサイズ増加（許容範囲内）
- **Follow-up**: バージョン互換性の継続確認

### Decision: エラー分類体系
- **Context**: バックエンドのエラーコードをクライアントで適切に処理する必要
- **Alternatives Considered**:
  1. 単一ApiExceptionクラス — シンプルだが分岐が複雑化
  2. エラー種別ごとのサブクラス — 型安全だがクラス数増加
  3. sealed class + パターンマッチング — Dart 3の機能を活用
- **Selected Approach**: sealed classによるエラー階層（`ApiException`基底クラス + 派生クラス）
- **Rationale**: Dart 3のsealed classでexhaustiveなパターンマッチングが可能
- **Trade-offs**: Dart 3必須（プロジェクトはSDK 3.9.0で対応済み）
- **Follow-up**: なし

### Decision: 認証状態管理
- **Context**: Firebase認証状態をアプリ全体で参照し、APIリクエストに反映
- **Alternatives Considered**:
  1. グローバルシングルトン — シンプルだがテスト困難
  2. Riverpod Provider — 既存の状態管理と統合可能
- **Selected Approach**: Riverpod StreamProviderでFirebase Auth状態を監視
- **Rationale**: 既存のRiverpod基盤と統合、リアクティブな状態管理
- **Trade-offs**: Provider依存（既に採用済みなので問題なし）
- **Follow-up**: なし

## Risks & Mitigations
- **Risk 1**: Dioのメジャーバージョンアップによる破壊的変更 — バージョン固定で対応
- **Risk 2**: Firebase SDKの更新によるAPI変更 — FlutterFireの公式ドキュメントを継続監視
- **Risk 3**: ネットワーク不安定時のユーザー体験低下 — リトライ機構とオフライン検知で対応

## References
- [Dio Package - pub.dev](https://pub.dev/packages/dio) — HTTPクライアントライブラリ
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview) — Firebase Flutter SDK公式ドキュメント
- [shared_preferences - pub.dev](https://pub.dev/packages/shared_preferences) — キーバリューストレージ
- [flutter_riverpod - pub.dev](https://pub.dev/packages/flutter_riverpod) — 状態管理ライブラリ
