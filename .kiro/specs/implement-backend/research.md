# Research & Design Decisions

## Summary
- **Feature**: `implement-backend`
- **Discovery Scope**: New Feature（グリーンフィールド - バックエンドAPI全体の新規構築）
- **Key Findings**:
  - Honoはapp.route()を使用したモジュラー構成を推奨、RoRスタイルのコントローラーは非推奨
  - PrismaはMySQL 8でInnoDB必須、ドライバーアダプター（v5.4+）でmariadbドライバー使用可能
  - Firebase Admin SDKのverifyIdToken()でBearer Token認証を実装

## Research Log

### Honoフレームワークのベストプラクティス
- **Context**: Cloud Run上で動作するREST API構築に最適なパターンを調査
- **Sources Consulted**:
  - [Hono Best Practices](https://hono.dev/docs/guides/best-practices)
  - [Build a Blazing Fast API with Hono and Cloud Run](https://medium.com/google-cloud/build-a-blazing-fast-api-in-minutes-with-hono-and-cloud-run-d3548cba99a0)
- **Findings**:
  - RoRスタイルのコントローラーは型推論の問題があるため非推奨
  - `app.route()`を使用してモジュラーアプリケーションを構築する
  - RPC modeとZodバリデーターで型安全なAPIを実現
  - チェーンメソッドでRouteの型を正しく推論させる
  - Cloud Runへのソースベースデプロイでコンテナイメージ自動構築可能
- **Implications**:
  - ルートファイルを機能別に分割（championships.ts, answers.ts, users.ts）
  - Zodによる入力バリデーションを標準化
  - 型安全なルーティングのためチェーン構文を採用

### Prisma ORM with MySQL 8
- **Context**: Cloud SQL (MySQL 8.0) との接続とスキーマ設計のベストプラクティス
- **Sources Consulted**:
  - [Prisma MySQL Connector](https://www.prisma.io/docs/orm/overview/databases/mysql)
  - [Prisma Deep-Dive Handbook 2025](https://dev.to/mihir_bhadak/prisma-deep-dive-handbook-2025-from-zero-to-expert-1761)
- **Findings**:
  - MySQL 8のデフォルトエンジンはInnoDBだが、明示的に指定推奨
  - rootユーザーを使用せず、アプリケーション専用ユーザーを作成
  - `@@map`でPascalCaseモデル名をsnake_caseテーブル名にマッピング
  - `@@index`で頻繁にクエリされるフィールドにインデックスを設定
  - Connection poolingはサーバーレス環境で重要（シングルトンパターン）
  - Prisma v5.4+でDriver Adaptersが利用可能
- **Implications**:
  - PrismaClientはシングルトンで管理
  - リレーションフィールド（user_id, championship_id, answer_id）にインデックス追加
  - UUIDはPrisma組み込みの`uuid()`で生成

### Firebase Admin SDK認証
- **Context**: REST APIエンドポイントの保護と認証フロー設計
- **Sources Consulted**:
  - [Firebase Admin Node.js SDK](https://www.npmjs.com/package/firebase-admin)
  - [Securing Express API with Firebase Auth](https://dev.to/emeka/securing-your-express-node-js-api-with-firebase-auth-4b5f)
- **Findings**:
  - `admin.auth().verifyIdToken(idToken)`でIDトークン検証
  - Bearer Tokenパターン: `Authorization: Bearer <token>`
  - トークンからuid取得後、リクエストコンテキストに設定
  - 検証失敗時は401 Unauthorizedを返す
  - サービスアカウント認証情報で初期化
- **Implications**:
  - 認証ミドルウェアを共通化してすべての保護ルートに適用
  - 公開エンドポイントでは認証を任意（オプショナル）に設定
  - HonoのContext変数にユーザー情報を格納

### Cloud Storage署名付きURL
- **Context**: クライアントからの直接画像アップロード実装
- **Sources Consulted**:
  - [Signed URLs - Google Cloud Storage](https://cloud.google.com/storage/docs/access-control/signed-urls)
  - [Secure File Upload to GCS Using Signed URLs](https://medium.com/@cloudandnodejstutorials/secure-file-upload-to-google-cloud-storage-using-signed-urls-with-nodeh-a-comprehensive-guide-c24a3802dbe3)
- **Findings**:
  - `@google-cloud/storage`ライブラリの`getSignedUrl()`を使用
  - action: 'write'で書き込み用URL生成
  - 有効期限（expires）を設定（例: 15分）
  - Content-Typeの制限をオプションで設定可能
  - 署名付きURLはXML APIエンドポイントでのみ動作
- **Implications**:
  - 画像アップロード用のエンドポイントで署名付きURL生成
  - Content-Typeをimage/*に制限
  - 有効期限は15分程度に設定

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| レイヤードアーキテクチャ | Routes → Services → Repositories | シンプル、理解しやすい | 大規模化時に境界が曖昧に | 小〜中規模に適切 |
| クリーンアーキテクチャ | UseCases → Entities → Repositories | 高いテスタビリティ | 過剰な抽象化のリスク | MVPには重すぎる |
| モジュラーモノリス | 機能別モジュール（championships, answers等） | 関心の分離、将来の分解容易 | モジュール間依存管理 | **採用** |

**選択理由**: モジュラーモノリスはHonoの`app.route()`パターンと親和性が高く、機能別にルート、サービス、リポジトリを整理できる。将来的なマイクロサービス分解にも対応可能。

## Design Decisions

### Decision: ルーティング構造
- **Context**: APIエンドポイントの整理とコード分割方法
- **Alternatives Considered**:
  1. 単一ファイル — すべてのルートを1つのファイルに
  2. 機能別ファイル分割 — championships.ts, answers.ts, users.ts
- **Selected Approach**: 機能別ファイル分割
- **Rationale**: Honoのベストプラクティスに準拠、関心の分離
- **Trade-offs**: ファイル数増加 vs 保守性向上
- **Follow-up**: ルート間の共通処理はミドルウェアで統一

### Decision: 認証フロー
- **Context**: APIエンドポイントの保護方式
- **Alternatives Considered**:
  1. グローバルミドルウェア — 全ルートに適用、公開ルートは除外リスト
  2. ルート別ミドルウェア — 保護ルートのみに適用
- **Selected Approach**: ルート別ミドルウェア
- **Rationale**: 明示的な保護範囲、柔軟な認証レベル（必須/任意）対応
- **Trade-offs**: 各ルートでの明示的指定が必要 vs セキュリティの明確化
- **Follow-up**: オプショナル認証ミドルウェアも用意（閲覧時のユーザー情報取得用）

### Decision: 選手権ステータス管理
- **Context**: 募集中→選定中の自動遷移をどう実装するか
- **Alternatives Considered**:
  1. バッチジョブ — Cloud Schedulerで定期更新
  2. クエリ時動的判定 — end_atと現在時刻を比較
- **Selected Approach**: クエリ時動的判定
- **Rationale**: バッチジョブのオーバーヘッド回避、リアルタイム性確保
- **Trade-offs**: 毎クエリでの計算 vs 状態の即時反映
- **Follow-up**: 計算済みstatusをレスポンスに含める関数を共通化

### Decision: エラーハンドリング形式
- **Context**: 一貫したAPIエラーレスポンス形式
- **Alternatives Considered**:
  1. RFC 7807 Problem Details — 標準化された形式
  2. シンプルなcode/message形式 — 要件に記載の形式
- **Selected Approach**: シンプルなcode/message形式
- **Rationale**: 要件定義に準拠、フロントエンド実装の簡易化
- **Trade-offs**: 標準非準拠 vs シンプルさ
- **Follow-up**: 必要に応じてdetailsフィールドを追加

## Risks & Mitigations
- **Cloud SQL接続の安定性** — Connection poolingとシングルトンパターンで対応
- **Firebase認証レイテンシ** — トークン検証キャッシュ検討（将来）
- **画像アップロードサイズ** — 署名付きURLでContent-Length制限を設定
- **同時書き込みの競合** — Like追加時のユニーク制約で409 Conflict返却

## References
- [Hono Documentation](https://hono.dev/docs/) — 公式ドキュメント
- [Prisma MySQL Guide](https://www.prisma.io/docs/orm/overview/databases/mysql) — MySQL接続設定
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup) — 認証実装
- [Cloud Storage Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls) — 署名付きURL仕様
