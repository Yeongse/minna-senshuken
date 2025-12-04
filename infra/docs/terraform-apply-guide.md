# Terraform実行手順書

## 前提条件

- [ ] GCPプロジェクトが作成済み
- [ ] 請求先アカウントが紐付け済み
- [ ] gcloud CLIがインストール済み
- [ ] Terraformがインストール済み（>= 1.0）

## 手順

### 1. gcloud認証

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <YOUR_PROJECT_ID>
```

### 2. 変数ファイル作成

```bash
cd infra
cat > terraform.tfvars << 'EOF'
project_id = "<YOUR_PROJECT_ID>"
region     = "asia-northeast1"
EOF
```

### 3. Terraform初期化

```bash
terraform init
```

### 4. プラン確認

```bash
terraform plan
```

### 5. インフラ構築

```bash
terraform apply
```

確認プロンプトで `yes` を入力。

### 6. 出力値確認

```bash
terraform output
```

出力例：
- `cloud_run_url` - APIエンドポイント
- `storage_bucket_name` - 画像保存バケット
- `artifact_registry_path` - Dockerイメージパス
- `service_account_email` - サービスアカウント

## バックエンドデプロイ

インフラ構築後：

```bash
# Artifact Registry認証
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# デプロイ実行
export PROJECT_ID="<YOUR_PROJECT_ID>"
./deploy.sh
```

## トラブルシューティング

| エラー | 対処 |
|-------|-----|
| API未有効化 | `terraform apply`を再実行（自動有効化） |
| 権限エラー | `gcloud auth application-default login`を再実行 |
| ステートバケットエラー | `./setup-state-bucket.sh`を実行 |
