# Requirements Document

## Introduction

本ドキュメントは「みんなの選手権」アプリケーションのGCPインフラストラクチャ構築に関する要件を定義する。バックエンド（Hono/Node.js + Prisma/MariaDB）およびモバイルクライアント（Flutter + Firebase）を支えるクラウドインフラを、最小コストで構築することを目的とする。

**前提条件**:
- GCPプロジェクトは作成済み
- 請求先アカウントは紐付け済み
- 本番/ステージング環境の分離は不要（単一環境）
- ユーザ規模は不明のため、スケール時はマニュアル対応可

**技術スタック**:
- バックエンド: Hono (Node.js 20+), Prisma, MariaDB
- ストレージ: Cloud Storage（画像保存）
- 認証: Firebase Authentication
- モバイル: Flutter (firebase_auth, firebase_core)
- インフラ管理: Terraform

**ネットワーク構成**:
- Cloud SQLはプライベートVPC内に配置
- Cloud RunはDirect VPC Egressを使用してプライベートVPC内のCloud SQLに直接接続

## Requirements

### Requirement 1: GCP APIの有効化

**Objective:** As a 開発者, I want GCPの必要なAPIをTerraformで一括有効化できる, so that インフラ構築の準備を自動化できる

#### Acceptance Criteria
1. When terraform applyを実行する, the Terraform shall Cloud Run API を有効化する
2. When terraform applyを実行する, the Terraform shall Cloud SQL Admin API を有効化する
3. When terraform applyを実行する, the Terraform shall Cloud Storage API を有効化する
4. When terraform applyを実行する, the Terraform shall Secret Manager API を有効化する
5. When terraform applyを実行する, the Terraform shall Artifact Registry API を有効化する
6. When terraform applyを実行する, the Terraform shall Cloud Build API を有効化する
7. When terraform applyを実行する, the Terraform shall Compute Engine API を有効化する
8. When terraform applyを実行する, the Terraform shall Service Networking API を有効化する
9. If APIの有効化に失敗した場合, then the Terraform shall エラーメッセージと失敗したAPI名を表示する

### Requirement 2: VPCネットワークの構築

**Objective:** As a 開発者, I want プライベートVPCネットワークをTerraformで構築する, so that Cloud SQLをプライベートネットワーク内に配置しセキュアに接続できる

#### Acceptance Criteria
1. The Terraform shall カスタムVPCネットワークを作成する
2. The Terraform shall asia-northeast1 リージョンにサブネットを作成する
3. The Terraform shall サブネットのIPレンジを /24 で設定する
4. The Terraform shall プライベートサービス接続用のIPレンジを予約する
5. The Terraform shall Service Networking APIを使用してプライベートサービス接続を確立する
6. When terraform applyが完了した, the Terraform shall VPCネットワーク名とサブネット名を出力する
7. If VPCネットワークの作成に失敗した場合, then the Terraform shall エラー原因を表示して処理を中断する

### Requirement 3: Cloud SQL (MySQL) インスタンスの構築

**Objective:** As a 開発者, I want 最小構成のCloud SQLインスタンスをプライベートVPC内にTerraformで構築する, so that Prismaからセキュアにデータベースに接続できる

#### Acceptance Criteria
1. The Terraform shall Cloud SQL for MySQLインスタンスを db-f1-micro（最小）マシンタイプで作成する
2. The Terraform shall インスタンスのストレージサイズを 10GB（SSD）に設定する
3. The Terraform shall 高可用性を無効化し、単一ゾーン構成とする
4. The Terraform shall 自動バックアップを有効化する（1日1回、保持期間7日）
5. The Terraform shall Cloud SQLインスタンスをプライベートVPCネットワークに接続する
6. The Terraform shall パブリックIPを無効化し、プライベートIPのみを有効化する
7. The Terraform shall アプリケーション用データベースとユーザを作成する
8. When terraform applyが完了した, the Terraform shall 接続情報（インスタンス名、プライベートIP）を出力する
9. If Cloud SQLインスタンスの作成に失敗した場合, then the Terraform shall エラー原因を表示して処理を中断する

### Requirement 4: Cloud Storageバケットの構築

**Objective:** As a 開発者, I want 画像アップロード用のCloud StorageバケットをTerraformで作成する, so that ユーザがアップロードした画像を保存できる

#### Acceptance Criteria
1. The Terraform shall 画像保存用のCloud Storageバケットを作成する
2. The Terraform shall バケットのロケーションを asia-northeast1（東京）に設定する
3. The Terraform shall ストレージクラスを Standard に設定する
4. The Terraform shall 公開アクセスを禁止する（均一バケットレベルアクセス）
5. The Terraform shall ライフサイクルルールで90日以上経過した一時ファイルを自動削除する設定を追加する
6. When terraform applyが完了した, the Terraform shall バケット名を出力する

### Requirement 5: Artifact Registryリポジトリの構築

**Objective:** As a 開発者, I want Dockerイメージ用のArtifact RegistryリポジトリをTerraformで作成する, so that バックエンドのコンテナイメージを保存できる

#### Acceptance Criteria
1. The Terraform shall Docker形式のArtifact Registryリポジトリを作成する
2. The Terraform shall リポジトリのロケーションを asia-northeast1 に設定する
3. When terraform applyが完了した, the Terraform shall リポジトリのフルパスを出力する

### Requirement 6: Cloud Runサービスの構築

**Objective:** As a 開発者, I want バックエンドAPIをCloud RunにTerraformでデプロイし、プライベートVPC内のCloud SQLに直接接続する, so that セキュアにAPIエンドポイントを公開できる

#### Acceptance Criteria
1. The Terraform shall Cloud Runサービスを asia-northeast1 リージョンに作成する
2. The Terraform shall 最小インスタンス数を 0（コールドスタート許容）に設定する
3. The Terraform shall 最大インスタンス数を 2 に制限する
4. The Terraform shall メモリを 512Mi に設定する
5. The Terraform shall CPUを 1 に設定する
6. The Terraform shall Direct VPC Egressを設定し、Cloud Runをプライベートサブネットに接続する
7. The Terraform shall VPCアクセスのEgressを「private-ranges-only」に設定する
8. The Terraform shall Secret Managerから環境変数（DATABASE_URL等）を参照する設定を含める
9. The Terraform shall 未認証アクセスを許可する（パブリックAPI）
10. When terraform applyが完了した, the Terraform shall サービスURLを出力する

### Requirement 7: Secret Managerによるシークレット管理

**Objective:** As a 開発者, I want データベース接続情報等の機密情報をTerraformでSecret Managerに登録する, so that セキュアにシークレットを扱える

#### Acceptance Criteria
1. The Terraform shall DATABASE_URL用のシークレットを作成する
2. The Terraform shall FIREBASE_PROJECT_ID用のシークレットを作成する
3. The Terraform shall Cloud Runサービスアカウントにシークレットアクセス権限を付与する
4. When terraform applyが完了した, the Terraform shall 作成されたシークレット名一覧を出力する
5. If シークレット値が未設定の場合, then the Terraform shall プレースホルダー値で作成し、手動更新が必要な旨を通知する

### Requirement 8: サービスアカウントとIAM設定

**Objective:** As a 開発者, I want 最小権限のサービスアカウントをTerraformで設定する, so that セキュアにGCPリソースにアクセスできる

#### Acceptance Criteria
1. The Terraform shall Cloud Run用のサービスアカウントを作成する
2. The Terraform shall サービスアカウントに Cloud SQL Client ロールを付与する
3. The Terraform shall サービスアカウントに Storage Object Admin ロールを付与する
4. The Terraform shall サービスアカウントに Secret Manager Secret Accessor ロールを付与する
5. When terraform applyが完了した, the Terraform shall サービスアカウントのメールアドレスを出力する

### Requirement 9: Firebase プロジェクト設定手順

**Objective:** As a 開発者, I want Firebase設定の手動手順が文書化されている, so that Firebase Authenticationを正しく設定できる

#### Acceptance Criteria
1. The Documentation shall Firebaseコンソールでのプロジェクト作成手順を記載する
2. The Documentation shall Firebase AuthenticationでGoogleサインインを有効化する手順を記載する
3. The Documentation shall Flutter用のFirebase設定ファイル取得手順を記載する
4. The Documentation shall バックエンド用のサービスアカウントキー取得手順を記載する
5. The Documentation shall Firebase Admin SDKの初期化に必要な環境変数一覧を記載する

### Requirement 10: デプロイ自動化スクリプト

**Objective:** As a 開発者, I want バックエンドのビルドとデプロイを自動化するスクリプトを実行できる, so that 手動作業を最小化できる

#### Acceptance Criteria
1. When デプロイスクリプトを実行する, the Deploy Script shall Dockerイメージをビルドする
2. When デプロイスクリプトを実行する, the Deploy Script shall イメージをArtifact Registryにプッシュする
3. When デプロイスクリプトを実行する, the Deploy Script shall Cloud Runサービスを新しいイメージで更新する
4. If ビルドに失敗した場合, then the Deploy Script shall エラーを表示してデプロイを中断する
5. When デプロイが完了した, the Deploy Script shall デプロイされたリビジョンとURLを表示する

### Requirement 11: コスト最適化設定

**Objective:** As a プロジェクトオーナー, I want インフラコストを最小限に抑える, so that 開発・運用コストを低く維持できる

#### Acceptance Criteria
1. The Cloud SQL shall db-f1-micro インスタンスを使用して月額コストを最小化する
2. The Cloud Run shall 最小インスタンス数を0にしてアイドル時のコストを削減する
3. The Cloud Storage shall Standard ストレージクラスを使用する（頻繁なアクセス想定）
4. The Documentation shall 課金アラートの設定手順を含める
5. While 月額予算を設定している場合, the GCP shall 予算の50%、90%、100%到達時にアラート通知を送信する

### Requirement 12: Terraformステート管理

**Objective:** As a 開発者, I want TerraformのステートをCloud Storageで管理する, so that チームで安全にインフラを管理できる

#### Acceptance Criteria
1. The Terraform shall GCS バックエンドを使用してステートファイルを保存する
2. The Terraform shall ステートファイル用のCloud Storageバケットを作成する
3. The Terraform shall ステートロック機能を有効化する
4. The Terraform shall ステートファイルのバージョニングを有効化する
5. When terraform initを実行する, the Terraform shall リモートバックエンドに接続する

