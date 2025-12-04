# Implementation Plan

## Tasks

- [x] 1. Terraformプロジェクト基盤を構築する
- [x] 1.1 Terraformステートバケットを作成する
  - gcloudコマンドでステート保存用のCloud Storageバケットを作成
  - オブジェクトバージョニングを有効化してステート履歴を保持
  - 均一バケットレベルアクセスを設定してセキュリティを強化
  - _Requirements: 12.2, 12.3, 12.4_

- [x] 1.2 Terraform設定ファイルを作成する
  - プロバイダー設定（hashicorp/google >= 5.0）を定義
  - GCSバックエンド設定でリモートステート管理を構成
  - 入力変数（project_id, region）を定義
  - terraform initでバックエンド接続を確認
  - _Requirements: 12.1, 12.5_

- [x] 1.3 GCP APIを有効化するリソースを定義する
  - Cloud Run、Cloud SQL Admin、Cloud Storage、Secret Manager、Artifact Registry、Cloud Build、Compute Engine、Service Networking APIの8つを定義
  - for_eachで一括管理し、disable_on_destroy = falseを設定
  - terraform applyで有効化を実行し、エラー時はAPI名を含むメッセージを確認
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_

- [x] 2. VPCネットワーク基盤を構築する
- [x] 2.1 VPCネットワークとサブネットを作成する
  - カスタムVPCネットワークをauto_create_subnetworks=falseで作成
  - asia-northeast1リージョンに10.0.0.0/24のサブネットを作成
  - API有効化への依存関係を設定
  - VPCネットワーク名とサブネット名を出力
  - _Requirements: 2.1, 2.2, 2.3, 2.6_

- [x] 2.2 Private Services Accessを設定する
  - プライベートサービス接続用のIPレンジ（/20）を予約
  - google_service_networking_connectionでVPCピアリング接続を確立
  - エラー時は原因を表示して処理を中断
  - _Requirements: 2.4, 2.5, 2.7_

- [x] 3. Cloud SQLインスタンスを構築する
- [x] 3.1 Cloud SQL for MySQLインスタンスを作成する
  - db-f1-microティアで最小コスト構成を設定
  - 10GB SSDストレージを設定
  - プライベートIPのみ有効（ipv4_enabled = false）でパブリックIPを無効化
  - 単一ゾーン構成（availability_type = ZONAL）で高可用性を無効化
  - 自動バックアップを有効化（毎日03:00開始、7日保持）
  - Private Services Accessへの依存関係を設定してプライベートVPCに接続
  - インスタンス名とプライベートIPを出力
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.8, 3.9, 11.1_

- [x] 3.2 データベースとユーザーを作成する
  - アプリケーション用データベースを作成
  - アプリケーション用ユーザーを作成
  - random_passwordでセキュアなパスワードを生成
  - _Requirements: 3.7_

- [x] 4. サポートリソースを構築する
- [x] 4.1 (P) Cloud Storageバケットを作成する
  - 画像保存用バケットをasia-northeast1に作成
  - Standardストレージクラスを設定
  - 均一バケットレベルアクセスを有効化し、公開アクセスを禁止
  - 90日経過したtmp/プレフィックスの一時ファイルを自動削除するライフサイクルルールを設定
  - バケット名を出力
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 11.3_

- [x] 4.2 (P) Artifact Registryリポジトリを作成する
  - Docker形式のリポジトリをasia-northeast1に作成
  - リポジトリのフルパスを出力
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 5. セキュリティ設定を構築する
- [x] 5.1 Cloud Run用サービスアカウントを作成する
  - 専用サービスアカウントを作成
  - Cloud SQL Client、Storage Object Admin、Secret Manager Secret Accessor、Compute Network Userロールを付与
  - サービスアカウントのメールアドレスを出力
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 5.2 Secret Managerでシークレットを管理する
  - DATABASE_URL用シークレットを作成
  - FIREBASE_PROJECT_ID用シークレットを作成
  - Cloud SQLの接続情報からDATABASE_URLを自動生成してシークレット値を設定
  - サービスアカウントへのシークレットアクセス権を付与
  - 作成されたシークレット名一覧を出力
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 6. Cloud Runサービスを構築する
- [x] 6.1 Cloud Runサービスリソースを定義する
  - google_cloud_run_v2_serviceでasia-northeast1リージョンにサービスを定義
  - メモリ512Mi、CPU 1を設定
  - 最小インスタンス0（コールドスタート許容）、最大インスタンス2を設定
  - Secret Managerから環境変数（DATABASE_URL、FIREBASE_PROJECT_ID）を参照
  - サービスURLを出力
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.8, 6.10, 11.2_

- [x] 6.2 Direct VPC Egressを設定する
  - vpc_access.network_interfacesでVPCネットワークとサブネットを指定
  - egress = "PRIVATE_RANGES_ONLY"を設定してプライベートレンジのみにEgressを制限
  - _Requirements: 6.6, 6.7_

- [x] 6.3 パブリックアクセスを許可する
  - google_cloud_run_v2_service_iam_memberでallUsersにroles/run.invokerを付与
  - 未認証アクセスを許可
  - _Requirements: 6.9_

- [x] 7. デプロイスクリプトを作成する
- [x] 7.1 バックエンドデプロイスクリプトを実装する
  - Dockerイメージのビルドコマンドを実装
  - Artifact Registryへのプッシュコマンドを実装
  - gcloud run deployコマンドでCloud Runサービスを更新
  - set -eでエラー時の処理中断を実装
  - デプロイ後にリビジョンとサービスURLを出力
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 8. ドキュメントを作成する
- [x] 8.1 (P) Firebase設定手順ドキュメントを作成する
  - Firebaseコンソールでのプロジェクト作成手順を記載
  - Firebase AuthenticationでGoogleサインインを有効化する手順を記載
  - Flutter用設定ファイル（google-services.json、GoogleService-Info.plist）取得手順を記載
  - バックエンド用サービスアカウントキー取得手順を記載
  - Firebase Admin SDKの初期化に必要な環境変数一覧を記載
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 8.2 (P) インフラREADMEを作成する
  - 前提条件（GCPプロジェクト作成済み、請求先アカウント紐付け済み、gcloud CLI）を記載
  - セットアップ手順（terraform init/plan/apply）を記載
  - 課金アラートの設定手順（50%、90%、100%到達時）を記載
  - デプロイスクリプトの使用方法を記載
  - _Requirements: 11.4, 11.5_

- [x] 9. 統合テストを実施する
- [x] 9.1 Terraform構成を検証する
  - terraform validateで構文検証を実行
  - terraform planで変更内容を確認
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1_

- [x] 9.2 インフラ構築を実行する
  - terraform applyでリソースを作成
  - 全リソースの作成完了を確認
  - 出力値（Cloud Run URL、Cloud SQL Private IP、Storage Bucket名、Artifact Registry Path、Service Account Email）を確認
  - **手順書作成済み**: `infra/docs/terraform-apply-guide.md`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5_
