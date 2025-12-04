#!/bin/bash
# Terraform state bucket setup script
# This bucket must be created BEFORE running terraform init
# Requirements: 12.2, 12.3, 12.4

set -e

PROJECT_ID="${PROJECT_ID:?PROJECT_ID is required}"
BUCKET_NAME="minna-senshuken-tf-state"
REGION="asia-northeast1"

echo "Creating Terraform state bucket..."

# Create bucket with uniform bucket-level access
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

# Enable versioning for state history
gcloud storage buckets update "gs://${BUCKET_NAME}" \
  --versioning

echo "Terraform state bucket created successfully!"
echo "Bucket: gs://${BUCKET_NAME}"
echo ""
echo "Next steps:"
echo "1. cd infra"
echo "2. terraform init"
echo "3. terraform plan -var=\"project_id=${PROJECT_ID}\""
echo "4. terraform apply -var=\"project_id=${PROJECT_ID}\""
