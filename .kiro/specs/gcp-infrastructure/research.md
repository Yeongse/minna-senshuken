# Research & Design Decisions

## Summary
- **Feature**: `gcp-infrastructure`
- **Discovery Scope**: New Feature (greenfield)
- **Key Findings**:
  - Terraform `google_cloud_run_v2_service` は `vpc_access.network_interfaces` ブロックでDirect VPC Egressをサポート
  - Cloud SQL Private Services AccessはTerraformで `google_service_networking_connection` リソースを使用して構成
  - GCS バックエンドでステート管理、オブジェクトバージョニングとステートロックを有効化

## Research Log

### Terraform Cloud Run v2 Direct VPC Egress

- **Context**: TerraformでCloud RunのDirect VPC Egressを設定する方法
- **Sources Consulted**:
  - [google_cloud_run_v2_service | Terraform Registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)
  - [Direct VPC egress with a VPC network | Cloud Run](https://docs.cloud.google.com/run/docs/configuring/vpc-direct-vpc)
  - [GitHub Issue #15568 - Direct VPC egress support](https://github.com/hashicorp/terraform-provider-google/issues/15568)
- **Findings**:
  - `google_cloud_run_v2_service` の `vpc_access.network_interfaces` ブロックでDirect VPC Egressを設定
  - `network` と `subnetwork` を指定（少なくとも1つは必須）
  - `egress` は `PRIVATE_RANGES_ONLY` または `ALL_TRAFFIC` を指定
  - `tags` でネットワークタグを指定可能
  - 現在は単一のネットワークインターフェースのみサポート
- **Implications**: `google_cloud_run_v2_service` を使用し、`vpc_access.network_interfaces` でVPC接続を構成

### Terraform Cloud SQL Private Services Access

- **Context**: TerraformでCloud SQLをプライベートVPCに接続する方法
- **Sources Consulted**:
  - [Configure private services access | Cloud SQL for MySQL](https://cloud.google.com/sql/docs/mysql/configure-private-services-access)
  - [How to Deploy a Cloud SQL DB with a Private IP only, using Terraform](https://medium.com/swlh/how-to-deploy-a-cloud-sql-db-with-a-private-ip-only-using-terraform-e184b08eca64)
  - [Enable Private Service Connect on Cloud SQL (Terraform)](https://codelabs.developers.google.com/codelabs/psc-psa-cloudsql-terraform)
- **Findings**:
  - 3つのリソースが必要:
    1. `google_compute_global_address` - IPレンジ予約（`purpose = "VPC_PEERING"`）
    2. `google_service_networking_connection` - プライベート接続作成
    3. `google_sql_database_instance` - Cloud SQLインスタンス（`private_network` 指定）
  - `private_network` は `projects/PROJECT_ID/global/networks/NETWORK_NAME` 形式
  - `ipv4_enabled = false` でパブリックIPを無効化
  - `depends_on` で `google_service_networking_connection` への依存を明示
- **Implications**: 3つのリソースを適切な依存関係で構成

### Terraform GCS Backend State Management

- **Context**: Terraformステートの安全な管理方法
- **Sources Consulted**:
  - [Store Terraform state in a Cloud Storage bucket | Google Cloud](https://cloud.google.com/docs/terraform/resource-management/store-state)
  - [Backend Type: gcs | Terraform](https://developer.hashicorp.com/terraform/language/backend/gcs)
  - [Using the GCS Backend Block in Terraform](https://scalr.com/learning-center/using-the-gcs-backend-block-in-terraform/)
- **Findings**:
  - GCS バックエンドはステートロックを自動サポート
  - オブジェクトバージョニングを有効化して誤削除からの復旧を可能に
  - 専用バケットを作成し、アクセス制御を厳格に
  - `prefix` でステートファイルのパスを指定
  - 機密情報は環境変数または `-backend-config` で渡す
- **Implications**: ステートバケットは手動で事前作成（chicken-and-egg問題を回避）

### Direct VPC Egress vs Serverless VPC Access Connector

- **Context**: Cloud RunからプライベートVPC内のCloud SQLに接続する方法の選定
- **Sources Consulted**:
  - [Direct VPC egress with a VPC network | Cloud Run](https://cloud.google.com/run/docs/configuring/vpc-direct-vpc)
  - [How we optimized Cloud Run Networking with Direct VPC Egress](https://eagleeye.com/blog/how-we-optimized-cloud-run-networking-with-direct-vpc-egress)
  - [Connect from Cloud Run | Cloud SQL for MySQL](https://cloud.google.com/sql/docs/mysql/connect-run)
- **Findings**:
  - Serverless VPC Access ConnectorはCompute Engine VMとして課金され、Cloud Run料金の最大40%を占めることがある
  - Direct VPC EgressはCloud Runインスタンスに直接内部IPを割り当て、ネットワークEgressのみ課金
  - Direct VPC Egressは遅延が低く、スループットが高い（インスタンスあたり最大1Gbps）
  - Direct VPC Egressでは自分でファイアウォールルールを設定する必要がある
  - 起動時に接続確立に1分以上かかる場合があり、HTTPスタートアッププローブでリトライ設定を推奨
- **Implications**: コスト最小化要件に合致するため、Direct VPC Egressを採用

### Cloud SQL MariaDB 互換性

- **Context**: 既存コードがMariaDBドライバーを使用しているがCloud SQLはMariaDBをサポートしない
- **Sources Consulted**:
  - [Prisma MySQL database connector](https://www.prisma.io/docs/orm/overview/databases/mysql)
  - [@prisma/adapter-mariadb - npm](https://www.npmjs.com/package/@prisma/adapter-mariadb)
  - [Cloud SQL pricing | Google Cloud](https://cloud.google.com/sql/pricing)
- **Findings**:
  - Cloud SQLはMySQL、PostgreSQL、SQL Serverのみサポート（MariaDBなし）
  - 既存のPrismaスキーマは `provider = "mysql"` を使用
  - `@prisma/adapter-mariadb` はMySQL/MariaDB両方に互換性あり
  - `mariadb` Node.jsドライバーは全MySQLデータベースで動作
- **Implications**: Cloud SQL for MySQLを使用し、既存のMariaDBドライバー構成をそのまま利用可能

### Cloud SQL db-f1-micro 制限事項

- **Context**: 最小コスト構成のCloud SQLインスタンス
- **Sources Consulted**:
  - [About instance settings | Cloud SQL for MySQL](https://cloud.google.com/sql/docs/mysql/instance-settings)
  - [Google Cloud SQL Pricing](https://www.pump.co/blog/google-cloud-sql-pricing)
- **Findings**:
  - db-f1-microは共有コアCPU、低トラフィックワークロード向け
  - SLAの対象外（テスト・開発用途）
  - 推定月額コスト: 約$10（10GB SSD、低トラフィック）
  - ENTERPRISE_PLUS エディションでは使用不可
- **Implications**: ENTERPRISEエディションでdb-f1-microを使用、本番用途では将来的にスケールアップを検討

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Terraform (採用) | 宣言的IaCでGCPリソース管理 | 再現性、冪等性、ドリフト検出 | 学習コスト、ステート管理 | HashiCorp公式プロバイダー使用 |
| gcloud CLI スクリプト | 命令的スクリプト | シンプル、学習コスト低 | 冪等性の手動実装、ドリフト検出困難 | 不採用 |
| Direct VPC Egress (採用) | Cloud Runに直接内部IP割り当て | 低コスト、低遅延、スケールtoゼロ | ファイアウォール設定が必要 | `network_interfaces` ブロック使用 |
| Serverless VPC Access | マネージドコネクタVM経由 | 設定が簡単 | 追加コスト（VM課金） | 不採用 |

## Design Decisions

### Decision: Terraform を採用

- **Context**: インフラ管理ツールの選定
- **Alternatives Considered**:
  1. gcloud CLI スクリプト — シンプルだが冪等性の手動実装が必要
  2. Terraform — 宣言的IaC、状態管理、ドリフト検出
- **Selected Approach**: Terraform
- **Rationale**: 再現性の高いインフラ構築、チームでの共同作業、変更の追跡が容易
- **Trade-offs**: 初期学習コスト、ステートファイル管理の必要性
- **Follow-up**: GCSバックエンドでリモートステート管理を設定

### Decision: google_cloud_run_v2_service を使用

- **Context**: Cloud Run Terraformリソースの選定
- **Alternatives Considered**:
  1. `google_cloud_run_service` — v1 API、機能制限あり
  2. `google_cloud_run_v2_service` — v2 API、Direct VPC Egress対応
- **Selected Approach**: `google_cloud_run_v2_service`
- **Rationale**: Direct VPC Egressをネイティブサポート、最新機能利用可能
- **Trade-offs**: v2 APIの変更に追従する必要
- **Follow-up**: `vpc_access.network_interfaces` ブロックでVPC接続設定

### Decision: GCS Backend でステート管理

- **Context**: Terraformステートの保存場所
- **Alternatives Considered**:
  1. ローカルステート — シンプルだがチーム共有困難
  2. GCS Backend — リモート、ロック、バージョニング
  3. Terraform Cloud — マネージド、追加コスト
- **Selected Approach**: GCS Backend
- **Rationale**: GCP統合、追加コストなし、ステートロック対応
- **Trade-offs**: ステートバケットの事前作成が必要
- **Follow-up**: オブジェクトバージョニング有効化、IAMでアクセス制御

### Decision: Direct VPC Egress を採用

- **Context**: Cloud RunからCloud SQLへのプライベート接続方法
- **Alternatives Considered**:
  1. Serverless VPC Access Connector — マネージドVMを使用
  2. Cloud SQL Auth Proxy — サイドカーコンテナでプロキシ
  3. Direct VPC Egress — Cloud Runに直接内部IP割り当て
- **Selected Approach**: Direct VPC Egress
- **Rationale**: コスト最小化要件に最も合致。ネットワークEgressのみ課金でスケールtoゼロ。
- **Trade-offs**: ファイアウォールルールの手動設定が必要、起動時接続遅延の可能性
- **Follow-up**: スタートアッププローブでDB接続確認を実装

### Decision: Cloud SQL for MySQL を使用

- **Context**: 既存コードがMariaDBドライバーを使用
- **Alternatives Considered**:
  1. Cloud SQL for MySQL — GCPマネージドMySQL
  2. 外部MariaDBホスティング — 別プロバイダー使用
- **Selected Approach**: Cloud SQL for MySQL
- **Rationale**: `@prisma/adapter-mariadb` はMySQL互換。既存コード変更不要。GCPエコシステム統合。
- **Trade-offs**: 厳密なMariaDB固有機能は使用不可
- **Follow-up**: 接続文字列のホスト部分をCloud SQL Private IPに設定

## Risks & Mitigations

- **Terraformステート破損** — GCSバージョニング有効化、定期バックアップ
- **コールドスタート時の接続遅延** — HTTPスタートアッププローブでリトライ設定
- **db-f1-microの性能制限** — 負荷増加時にdb-g1-smallへスケールアップ
- **ファイアウォール設定ミス** — Terraformでファイアウォールルールを明示的に定義
- **Secret Manager値の手動設定漏れ** — terraform output でチェックリスト出力

## References

- [google_cloud_run_v2_service | Terraform Registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)
- [Store Terraform state in a Cloud Storage bucket | Google Cloud](https://cloud.google.com/docs/terraform/resource-management/store-state)
- [Backend Type: gcs | Terraform](https://developer.hashicorp.com/terraform/language/backend/gcs)
- [Configure private services access | Cloud SQL for MySQL](https://cloud.google.com/sql/docs/mysql/configure-private-services-access)
- [Direct VPC egress with a VPC network | Cloud Run](https://cloud.google.com/run/docs/configuring/vpc-direct-vpc)
- [@prisma/adapter-mariadb - npm](https://www.npmjs.com/package/@prisma/adapter-mariadb)
- [Cloud SQL pricing | Google Cloud](https://cloud.google.com/sql/pricing)
