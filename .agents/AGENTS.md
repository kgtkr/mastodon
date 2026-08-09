# Workspace Customizations

このリポジトリは、本家 [Mastodon](https://github.com/mastodon/mastodon) をフォークし、独自のカスタマイズや機能変更を加えて運用するためのリポジトリです。

以下に、このプロジェクトの構成、ブランチの運用方針、および作業するAIエージェントが従うべきルールを定義します。

---

## 1. ブランチの役割と運用方針

このリポジトリでは、本家の上流変更を追従しつつ独自カスタマイズを管理するため、以下のブランチ運用を行っています。

| ブランチ名 | 役割 | 運用方針・マージルール |
| :--- | :--- | :--- |
| **`kgtkr-master`** | 独自カスタマイズのメイン開発ブランチ | * 本家（upstream）の `main` に対応します。<br>* **独自の機能追加やカスタマイズのコミットは、このブランチに対して直接適用します。** |
| **`kgtkr-$MINOR_VERSION`**<br>(例: `kgtkr-4.6`) | 各マイナーバージョンのリリースブランチ | * 本家の `stable-$MINOR_VERSION` に対応します。<br>* **このブランチには直接独自のパッチをコミットしてはいけません。**<br>* `kgtkr-master` の変更と本家の特定リリースバージョンタグ（例: `v4.6.3`）をそれぞれマージして運用します。 |
| **`mstdn.kgtkr.net`** | サーバーデプロイ（イメージ構築）用ブランチ | * 実際に稼働させるサーバー用のブランチです。<br>* 常に最新の `kgtkr-$MINOR_VERSION` と同一のコミットを参照します。<br>* マイナーバージョン更新のたびに `git reset --hard kgtkr-$MINOR_VERSION` が実行されるため、**このブランチの履歴はマイナーバージョン変更時に破壊（改変）されます。** |

---

## 2. バージョンアップデート手順

本家の新しい安定版リリース（`vX.Y.Z`）を追従する際は、`kgtkr-update.sh` スクリプトまたは GitHub Actions の自動アップデートワークフローを使用します。

### ① GitHub Actions による自動アップデート（推奨フロー）
* **定期チェック (`kgtkr-auto-update-check.yml`)**:
  * 毎日定期実行（または手動実行）され、`upstream` の最新安定版タグをチェックします。
  * 未適用のアップデートがあれば、`kgtkr/update/vX.Y.Z` ブランチを作成し `./kgtkr-update.sh master <VERSION>` を実行します。
  * コンフリクトが発生した場合、`google-github-actions/run-gemini-cli` (Gemini CLI) がこの `AGENTS.md` の独自仕様ルールに基づき自動解消します。
  * コンフリクト解消後、`kgtkr-master` に向けた **Pull Request** が自動作成され、人間にレビューが依頼されます。
* **リリース・デプロイ (`kgtkr-auto-update-release.yml`)**:
  * 人間が PR をレビューしてマージすると発火し、`./kgtkr-update.sh release <VERSION>` を実行します。
  * `kgtkr-$MINOR_VERSION` および `mstdn.kgtkr.net` が更新（`PAT` により push）され、後続の Docker イメージ構築（`kgtkr-build-image.yml`）が自動でトリガーされます。

### ② `kgtkr-update.sh` のサブコマンド仕様
手動でアップデートを実行する場合、またはCIから部分的に呼ぶ場合はサブコマンドを使用します。

| サブコマンド | コマンド例 | 処理内容 |
| :--- | :--- | :--- |
| `master` | `./kgtkr-update.sh master 4.6.3` | `kgtkr-master` (または作業ブランチ) に `merge-base main vX.Y.Z` をマージ。 |
| `release` | `./kgtkr-update.sh release 4.6.3` | `kgtkr-$MINOR_VERSION` に `kgtkr-master` と `vX.Y.Z` をマージし、`mstdn.kgtkr.net` を `kgtkr-$MINOR_VERSION` へ強制リセット。 |
| `all` (既定) | `./kgtkr-update.sh 4.6.3` | `master` と `release` を連続実行（従来の手動一括更新動作）。 |

---

## 3. Dockerイメージ構築の仕組み

このプロジェクトは、カスタマイズを適用したコンテナイメージを構築するために特徴的な方法を採用しています。詳細は `kgtkr.Dockerfile` を参照してください。

* ビルド時に、公式のベースイメージ（`tootsuite/mastodon:$BASE_TAG`）との `git diff` を生成し、`kgtkr.diff` というパッチファイルを作成します。
* コンテナ内で `busybox patch` を用いて、公式イメージのコードに対してこのパッチを適用します。
* これにより、公式のビルド済みレイヤーを活かしつつ、このフォークリポジトリ独自の変更（アセットや設定、Rubyコードの修正など）を動的に適用したイメージを高速にビルドできます。

---

## 4. 独自カスタマイズ機能

このフォークリポジトリには、本家Mastodonに対して以下の独自カスタマイズが施されています。
本家タグ（例: `v4.6.3`）との差分は、以下のコマンド等で確認できます。

```sh
git diff v4.6.3 kgtkr-4.6
```

### ① 日本語全文検索の強化（Sudachiの導入）
* **対象ファイル**: `app/chewy/statuses_index.rb`
* **概要**: 日本語の全文検索精度を向上させるため、Elasticsearch用の日本語形態素解析プラグインである **Sudachi** (`sudachi_tokenizer`) をインデックスの解析器（Analyzer）に導入し、日本語特有の正規化・ストップワード処理フィルターを追加しています。

### ② 一般公開投稿の検索対象化
* **対象ファイル**: `app/chewy/statuses_index.rb`, `app/lib/search_query_transformer.rb`
* **概要**: 標準のMastodonは限定された範囲（自身の投稿など）のみ検索可能ですが、このカスタマイズにより一般公開のステータスに `searchable_by_anyone: true` フラグを付与してインデックス化し、全ユーザーが検索対象に含められるようクエリパーサーを拡張しています。

### ③ ディスク容量節約のためのヘッダー画像ダウンロードスキップ
* **対象ファイル**: `app/services/activitypub/process_account_service.rb`
* **概要**: 外部サーバーのアカウント（ActivityPubアクター）の情報を取得する際、サーバーディスクの容量を節約するためにヘッダー画像のダウンロードをスキップ（`unless true`）するよう制限しています。

---

## 5. エージェント向けの行動ガイドライン（作業ルール）

このリポジトリで作業するAIエージェントは、以下のルールを厳守してください。

* **独自機能やカスタマイズの追加・修正**
  * 必ず `kgtkr-master` ブランチ上で作業を行いコミットしてください。
  * `kgtkr-$MINOR_VERSION` や `mstdn.kgtkr.net` ブランチに直接カスタマイズコードをコミットしてはいけません。
* **コンフリクト発生時の対応**
  * アップデートマージの際にコンフリクトが発生した場合は、`kgtkr-master` に適用された独自仕様（例: ヘッダーダウンロードのスキップ等）を壊さないよう注意深くコードをマージしてください。
  * マージ完了後は本番環境用ブランチ（`mstdn.kgtkr.net`）へのデプロイ（強制リセットとプッシュ）を確実に行ってください。
