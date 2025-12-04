#!/bin/bash
# バックエンドデプロイスクリプト
# Requirements: 10.1, 10.2, 10.3, 10.4, 10.5

set -e

# 必須環境変数の確認
PROJECT_ID="${PROJECT_ID:?PROJECT_ID環境変数が必要です}"
REGION="${REGION:-asia-northeast1}"
SERVICE_NAME="minna-senshuken-api"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/minna-senshuken/api"
BACKEND_DIR="$(dirname "$0")/../backend"

echo "========================================"
echo "みんなの選手権 バックエンドデプロイ"
echo "========================================"
echo "Project: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service: ${SERVICE_NAME}"
echo "Image: ${IMAGE}"
echo "========================================"

# Requirement 10.1: Dockerイメージをビルドする
echo ""
echo "[1/3] Dockerイメージをビルド中..."
if ! docker build -t "${IMAGE}:latest" -f "${BACKEND_DIR}/Dockerfile" "${BACKEND_DIR}"; then
  # Requirement 10.4: ビルドに失敗した場合、エラーを表示してデプロイを中断する
  echo "エラー: Dockerイメージのビルドに失敗しました"
  exit 1
fi
echo "ビルド完了: ${IMAGE}:latest"

# Requirement 10.2: イメージをArtifact Registryにプッシュする
echo ""
echo "[2/3] Artifact Registryにプッシュ中..."
if ! docker push "${IMAGE}:latest"; then
  echo "エラー: イメージのプッシュに失敗しました"
  exit 1
fi
echo "プッシュ完了"

# Requirement 10.3: Cloud Runサービスを新しいイメージで更新する
echo ""
echo "[3/3] Cloud Runにデプロイ中..."
if ! gcloud run deploy "${SERVICE_NAME}" \
  --image="${IMAGE}:latest" \
  --region="${REGION}" \
  --project="${PROJECT_ID}"; then
  echo "エラー: Cloud Runへのデプロイに失敗しました"
  exit 1
fi

# Requirement 10.5: デプロイされたリビジョンとURLを表示する
echo ""
echo "========================================"
echo "デプロイ完了!"
echo "========================================"

# リビジョン情報を取得
REVISION=$(gcloud run revisions list \
  --service="${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(metadata.name)" \
  --limit=1)

# サービスURLを取得
URL=$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(status.url)")

echo "リビジョン: ${REVISION}"
echo "サービスURL: ${URL}"
echo "========================================"
