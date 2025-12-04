# みんなの選手権 インフラストラクチャ

このディレクトリには、「みんなの選手権」アプリケーションのGCPインフラストラクチャをTerraformで管理するための設定ファイルが含まれています。

## 前提条件

- GCPプロジェクトが作成済みであること
- GCPプロジェクトに請求先アカウントが紐付け済みであること
- 以下のツールがインストール済みであること：
  - [Terraform](https://www.terraform.io/downloads) >= 1.0
  - [gcloud CLI](https://cloud.google.com/sdk/docs/install)
  - [Docker](https://docs.docker.com/get-docker/)

## アーキテクチャ概要

```
┌─────────────────────────────────────────────────────────────┐
│                        GCP Project                          │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │  Cloud Run   │────▶│ Cloud SQL    │                     │
│  │  (API)       │     │ (MySQL)      │                     │
│  └──────┬───────┘     └──────────────┘                     │
│         │                   ▲                               │
│         │           Private VPC                             │
│         │         (Direct VPC Egress)                       │
│         ▼                                                   │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │Cloud Storage │     │Secret Manager│                     │
│  │  (Images)    │     │              │                     │
│  └──────────────┘     └──────────────┘                     │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐                     │
│  │  Artifact    │     │  TF State    │                     │
│  │  Registry    │     │  (GCS)       │                     │
│  └──────────────┘     └──────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

## ファイル構成

```
infra/
├── main.tf           # Provider設定、API有効化
├── variables.tf      # 入力変数
├── network.tf        # VPC、サブネット、Private Services Access
├── database.tf       # Cloud SQL
├── storage.tf        # Cloud Storage
├── registry.tf       # Artifact Registry
├── compute.tf        # Cloud Run
├── secrets.tf        # Secret Manager
├── iam.tf            # サービスアカウント、IAM
├── deploy.sh         # デプロイスクリプト
├── setup-state-bucket.sh  # ステートバケット初期化
├── README.md         # このファイル
└── docs/
    └── firebase-setup.md  # Firebase設定手順
```

## セットアップ手順

### 1. gcloud CLIの認証

```bash
# ログイン
gcloud auth login

# アプリケーションデフォルト認証
gcloud auth application-default login

# プロジェクト設定
gcloud config set project <YOUR_PROJECT_ID>
```

### 2. Terraformステートバケットの作成

初回のみ実行が必要です：

```bash
cd infra
./setup-state-bucket.sh
```

### 3. Terraform変数の設定

`terraform.tfvars` ファイルを作成します：

```hcl
project_id = "your-gcp-project-id"
region     = "asia-northeast1"
```

### 4. Terraformの初期化と適用

```bash
# 初期化
terraform init

# プランの確認
terraform plan

# インフラ構築
terraform apply
```

### 5. 出力値の確認

```bash
terraform output
```

主な出力値：
- `cloud_run_url` - Cloud RunサービスのURL
- `database_private_ip` - Cloud SQLのプライベートIP
- `storage_bucket_name` - Cloud Storageバケット名
- `artifact_registry_path` - Artifact Registryのパス
- `service_account_email` - サービスアカウントのメール

## デプロイ手順

バックエンドAPIのデプロイ：

```bash
# 環境変数の設定
export PROJECT_ID="your-gcp-project-id"
export REGION="asia-northeast1"

# Artifact Registryへの認証設定
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# デプロイ実行
./deploy.sh
```

## 課金アラートの設定

予算超過を防ぐため、課金アラートを設定することを推奨します。

### GCP Consoleでの設定手順

1. [GCP Console](https://console.cloud.google.com/) にアクセス
2. 「お支払い」>「予算とアラート」を選択
3. 「予算を作成」をクリック
4. 予算名を入力（例：`minna-senshuken-budget`）
5. 対象プロジェクトを選択
6. 予算額を設定（例：$20/月）
7. アラートしきい値を設定：
   - 50%到達時
   - 90%到達時
   - 100%到達時
8. 通知先メールアドレスを設定
9. 「保存」をクリック

### gcloud CLIでの設定

```bash
# 予算アラートの作成
gcloud billing budgets create \
  --billing-account=<BILLING_ACCOUNT_ID> \
  --display-name="minna-senshuken-budget" \
  --budget-amount=20USD \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0 \
  --filter-projects=projects/<PROJECT_ID>
```

## 推定月額コスト

| リソース | 設定 | 推定コスト |
|---------|------|-----------|
| Cloud SQL | db-f1-micro, 10GB SSD | ~$10/月 |
| Cloud Run | 0-2インスタンス、アイドル時0 | ~$0-5/月 |
| Cloud Storage | Standard、最小使用量 | ~$1/月 |
| Artifact Registry | 最小イメージ | ~$1/月 |
| GCS State Bucket | < 1MB | ~$0/月 |
| **合計** | | **~$12-17/月** |

※ 実際のコストは使用量により変動します。

## トラブルシューティング

### APIが有効化されていない

```bash
# 手動でAPIを有効化
gcloud services enable run.googleapis.com --project=<PROJECT_ID>
gcloud services enable sqladmin.googleapis.com --project=<PROJECT_ID>
# ... その他のAPI
```

### Cloud SQLへの接続エラー

1. Private Services Accessが正しく設定されているか確認
2. Cloud Runがプライベートサブネットに接続されているか確認
3. サービスアカウントに`roles/cloudsql.client`ロールがあるか確認

### Secret Managerへのアクセスエラー

1. サービスアカウントに`roles/secretmanager.secretAccessor`ロールがあるか確認
2. シークレットが作成されているか確認

### デプロイスクリプトエラー

1. Docker認証が設定されているか確認: `gcloud auth configure-docker`
2. 環境変数が正しく設定されているか確認
3. Dockerfileが存在するか確認

## クリーンアップ

インフラを削除する場合：

```bash
# 全リソースの削除（注意：データも削除されます）
terraform destroy

# ステートバケットは手動で削除
gsutil rm -r gs://minna-senshuken-tf-state
```

## 関連ドキュメント

- [Firebase設定手順](docs/firebase-setup.md)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [Cloud SQL ドキュメント](https://cloud.google.com/sql/docs)
