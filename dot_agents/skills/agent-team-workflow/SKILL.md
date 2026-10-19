---
name: agent-team-workflow
description: "5つの開発フェーズ（Collect, Analyze, Define, Architect, Implement）をClaude Code、Codex、Antigravity CLIの各エージェントをHerdrで協調させて完全自律実行し、ドラフトPRを作成するスキル。タスクの要件収集から実装・ブラウザQA・コード監査までを一気通貫で自動化する際に使用する。"
---

# Agent Team Workflow

複数AIエージェント（Claude Code, Codex, Antigravity CLI）がHerdr上で協調し、5段階のフェーズ（Collect, Analyze, Define, Architect, Implement）を経てタスクを完了し、Draft PRを作成する完全自律型開発ワークフローです。
このスキルを実行するエージェントが「**オーケストレーター**」として全体の進行、Herdrペイン管理、合否判定、差し戻し制御を担当します。

## エージェントの強みと役割分担

| エージェント | 主要な強み | 担う役割 |
|---|---|---|
| **Claude Code** (`claude`) | **自律的なタスク実行・実装推進力** | 情報収集の実装、テスト仕様切り出し、システム設計、プロダクションコード実装 |
| **Codex** (`codex`) | **厳密なタスク実行・論理検証** | 仕様レビュー（PRD・テスト仕様・アーキテクチャ）、コード・エビデンス監査 |
| **Antigravity CLI** (`agy`) | **大規模NLP・文書読解 & Chromeブラウザ操作/QA** | 原文ハルシネーション検証、PRD統合、ブラウザ操作を含むQAテスト実走 |

### フェーズ別マトリクス

| ステップ | フェーズ名 | 作業者 (Worker) | レビュワー (Reviewer) | QA | 成果物 |
|---|---|---|---|---|---|
| **1** | **Collect** | Claude Code (`claude`) | Antigravity CLI (`agy`) | N/A | `task-background.md`, `sources/` (非公開) |
| **2** | **Analyze** | Antigravity CLI (`agy`) | Codex (`codex`) | N/A | `PRD.md` |
| **3** | **Define** | Claude Code (`claude`) | Codex (`codex`) | N/A | `automated-tests.md`, `agentic-tests.md`, `manual-tests.md` |
| **4** | **Architect** | Claude Code (`claude`) | Codex (`codex`) | N/A | `system-design.md` |
| **5** | **Implement** | Claude Code (`claude`) | Codex (`codex`) | Antigravity CLI (`agy`) | プロダクションコード, テストコード, `qa-report-step5.md` |

---

## 運用共通ルール

1. **完全自律進行とエスカレーション**:
   - 各ステップは原則人間の介在なしで自律的に進行します。
   - レビューまたはQAで `STATUS: FAIL` が出た場合、最大 **3回** まで作業者に差し戻して修正させます。
   - 3回連続でPASSしなかった場合は処理を一時停止（Blocked状態）にし、人間にアラートと該当レビュー/QAレポートを提示して指示を仰ぎます。
2. **合否判定プロトコルと監査ログ（Attempt退避）**:
   - 各ステップのレビュワーおよびQAは、常に最新の判定を `review-step<N>.md`（または `qa-report-step5.md`）に出力します。
   - ファイルの先頭行には必ず `STATUS: PASS` または `STATUS: FAIL` を明記し、指摘事項や合否理由を箇条書きで具体的に記述します。
   - **リトライ履歴の退避**: 差し戻しが発生して再レビュー/再テストを行う際、前回のレポートは `review-step<N>-attempt<M>.md`（QAの場合は `qa-report-step5-attempt<M>.md`）として退避・保存し、常にイテレーションの差分履歴を追跡可能にします。
   - オーケストレーターは該当ファイルの先頭ステータスを読み取り、次ステップへの進行または差し戻しを機械的に判定します。
3. **セキュリティ・機密情報保護 (`.git/info/exclude`)**:
   - チーム共通の `.gitignore` を勝手に変更して他の開発者に影響を与えないよう、タスク開始時に `.git/info/exclude` を確認します。
   - `.git/info/exclude` に `sources/` が記載されていない場合は追記し、取得した生データ（Slack/Notion/Drive等の機密・個人情報）がGitにステージング・コミット・プッシュされないことを保証します。
4. **Herdrペイン・リソース管理**:
   - タスク開始時に専用タブを1つ作成します。
   - ステップごとに必要なペインを分割（`herdr pane split`）して該当エージェントを起動（`herdr agent start`）します。
   - ステップ完了（PASS）時に該当ステップのペインをクローズし、メモリ・トークン消費とコンテキスト肥大化を防止します（成果物はファイル経由で引き継がれます）。
5. **Gitブランチ運用**:
   - タスク開始時に専用のフィーチャーブランチ（`feature/<task-name>`）を自動作成します。
   - Step 5の全検証完了後、全成果物（ドキュメント群、実装コード、テストコード、QAレポート、レビューログ）をコミットし、リモートへプッシュしてDraft PRを作成します。

---

## 各ステップの詳細手順と合格基準

### Step 1: Collect (情報収集)
- **入力**: スキル引数に示された自然言語による情報ソース（GitHub, Notion, Slack, Google Drive, カレントディレクトリ内のメモファイル等）。
- **外部アクセス前提とエラー時対応**:
  - 指定されたソースへアクセスできない場合（401認証エラー、403権限不足、404リンク切れ、APIトークン未設定等）、作業者は勝手に推測して進めず、直ちにオーケストレーター経由で一時停止（Blocked状態）にし、人間に認証設定またはデータ提供を求めます。
- **作業者 (Claude Code)**:
  1. 指定された各ソースからタスクに関連する情報を取得します。
  2. 取得した生データ（APIレスポンス、Markdownエクスポート、Slackスレッド本文等）をローカルの `sources/` ディレクトリにスナップショットとして保存します。
  3. `task-background.md` に背景情報をまとめ、どの情報をどのソースから取得したかを **IEEE Reference Style** で明記します（`sources/` のファイルまたはURLへリンク）。
- **レビュワー (Antigravity CLI)**:
  - Antigravity CLIの長大コンテキストウィンドウ（1M+ トークン）を活かし、`task-background.md` のIEEE引用と `sources/` 内の実データを突合します。
  - 元ソースとの矛盾や、ソースが存在しないハルシネーションがないかを精査します。
  - `review-step1.md` に `STATUS: PASS` または `STATUS: FAIL` と検証結果を出力します。ハルシネーションや矛盾が見つかった場合は作業者に差し戻します。

### Step 2: Analyze (要件定義)
- **入力**: `task-background.md`
- **作業者 (Antigravity CLI)**:
  1. 高度なNLP能力を活かして `task-background.md` を要求仕様にまとめ、`PRD.md` を作成します。
  2. 機能要件および測定可能な非機能要件（性能・セキュリティ・可用性等）を半形式手法的に **Given... When... Then...** 形式で網羅的にリスト化します。
  3. 「前提条件・制約・スコープ外」セクションを独立して明記します。
  4. 背景情報に矛盾があった場合、最も合理的に整合すると思われる形に統合し、「矛盾点」「統合結果」「判断根拠」を記録する専用セクションを設けます。
  5. 根本的に相反するビジネス要求がありAIの推論のみで解決できない場合は、「要人間判断（Pending Human Decision）」として明記し、無理な仮定を置かないようにします。
- **レビュワー (Codex)**:
  - Codexの論理的厳密性を活かし、`task-background.md` と `PRD.md` 間の抜け漏れ・齟齬を精査します。
  - Given-When-Thenの境界条件や前提の漏れを検証します。
  - **矛盾解決の合否基準**: レビュワー自身の主観的好みで合否を判定するのではなく、「矛盾点・統合結果・判断根拠が論理的に筋が通っているか」を判定基準とします。論理的破綻がある場合は `STATUS: FAIL`、論理的に整合していれば `STATUS: PASS` とします。解決不能な重大事項が「要人間判断」として提起されている場合は一時停止して人間にエスカレーションします。

### Step 3: Define (テスト仕様策定)
- **入力**: `PRD.md`
- **テスト分類の明確な境界基準**:
  - **1. 決定論的自動テスト (最優先)** ➔ `automated-tests.md`:
    - コードスクリプトとして完全に決定論的・再現可能に記述できるもの。ユニットテスト、結合テスト、および **Playwright / Cypress などのスクリプト化可能なブラウザE2Eテスト** はすべてここに含まれます。
  - **2. エージェント操作による確率論的テスト** ➔ `agentic-tests.md`:
    - 固定スクリプト化が難しく、LLMやビジョンモデルが画面の文脈・レイアウト・自然言語応答を解釈しながら試行錯誤・探索的に操作・視覚検証する必要があるもの（非構造的UIの探索、デザイン崩れ・レイアウト崩れの視覚確認、LLM出力の文脈判定など）。
  - **3. 人間による手動確認 (最終手段)** ➔ `manual-tests.md`:
    - 人間による実機確認、決済連携、外部組織との協調、法的・運用的な目視確認など。
- **作業者 (Claude Code)**:
  - PRDの全要件（Given-When-Then）を上記優先度（1 > 2 > 3）で分類し、テスト仕様書（ID, 対応PRD要件ID, 入力, 期待値, 実行手順/コマンド案）を策定します。
- **レビュワー (Codex)**:
  - PRDの全要件がいずれかのテストでカバーされているか（網羅性）を確認します。
  - 自動テスト（スクリプト化）可能なものがエージェントテストや手動テストに割り振られていないか（優先度ルールの厳守）を精査します。
  - 記載の手順で客観的にテスト可能かを検証し、`review-step3.md` を作成します。

### Step 4: Architect (システム詳細設計)
- **入力**: `PRD.md`, `automated-tests.md`, `agentic-tests.md`, `manual-tests.md`
- **作業者 (Claude Code)**:
  1. 既存コードベースのアーキテクチャ・命名規則・ディレクトリ構造を探索した上で、要件およびテスト仕様を満たす詳細設計を `system-design.md` にまとめます（アーキテクチャ図、データモデル/スキーマ、API/インターフェース設計、コンポーネント構成）。
  2. **ISO/IEC 25010 の8品質特性対応表** を必須セクションとして設け、各特性に対する設計上の対策、または「該当なし(N/A)」と判断した根拠を明記します。
     - 機能適合性 (Functional Suitability)
     - 性能効率性 (Performance Efficiency)
     - 互換性 (Compatibility)
     - 使用性 (Usability)
     - 信頼性 (Reliability)
     - セキュリティ (Security)
     - 保守性 (Maintainability)
     - 移植性 (Portability)
- **レビュワー (Codex)**:
  - 設計が必要十分であり、PRDおよび各テスト仕様を漏れなくカバーしているかを確認します。
  - 過剰設計（YAGNI違反）や設計不足、既存コード規約との著しい不整合がないかを精査します。
  - 8つの品質特性観点で設計上のリスクや抜け漏れ、未考慮事項がないかを厳格に精査し、`review-step4.md` を作成します。

### Step 5: Implement (実装・QA・最終監査)
- **入力**: `system-design.md`, `automated-tests.md`, `agentic-tests.md`
- **作業者 (Claude Code)**:
  - 設計および自動テスト仕様に基づき、プロダクションコードおよび自動テストコード（ユニット/結合/E2Eスクリプト）を実装します。
- **QA (Antigravity CLI) — テスト環境ライフサイクル管理**:
  1. **サーバー起動とヘルスチェック**: WebアプリやAPIのテストが必要な場合、QAエージェント自身がバックグラウンドプロセスでローカル開発サーバー（例: `npm run dev`）を立ち上げ、疎通確認（HTTP 200等のヘルスチェック）を確認します。
  2. **テスト実行**:
     - `automated-tests.md` に基づく自動テストコマンドを実行し、エビデンス（実行ログ、終了コード）を取得します。
     - `agentic-tests.md` に基づく操作手順を実走します（特にGoogle Chromeや `terminal-browser` を用いた自律的UI/視覚シナリオ操作を行い、ログやキャプチャを取得）。
  3. **サーバー停止**: テスト実走完了後、起動したローカルサーバープロセスを確実にクリーンアップ・停止します。
  4. **レポート出力**: テスト結果を `qa-report-step5.md` にまとめます。未達テストがある場合は `STATUS: FAIL` として作業者に差し戻します。全テストが成功した場合は `STATUS: PASS` とします。
- **レビュワー (Codex)**:
  - QAがすべてPASSした後、`qa-report-step5.md` のエビデンスの妥当性（テストの形骸化、モックによる偽陽性、アサーションの抜けがないか）を厳格に監査します。
  - 実装コードの差分（`git diff`）を精査し、設計との適合性、コード品質、セキュリティ面をレビューし `review-step5.md` を作成します。
  - **差し戻しルール**: レビューでFAILとなった場合、作業者に修正させ、**修正後は必ず再度QA（Antigravity CLI）によるテスト実走を通してエビデンスを更新してから再レビュー**を行います。

---

## 完了・納品処理 (Draft PR作成)

Step 5のレビューが `STATUS: PASS` に達したら、オーケストレーターは以下の納品処理を実行します:

1. `sources/` が `.git/info/exclude` によってGit管理から除外されていることを再確認します。
2. すべての変更（成果物ドキュメント、実装、テスト、レビュー・QAレポート群）をステージングしてコミットします。
3. リモートブランチへプッシュ: `git push -u origin feature/<task-name>`
4. GitHub CLI (`gh`) を使用して **Draft PR** を作成します:
   ```bash
   gh pr create --draft --title "feat: <task-title>" --body-file - << 'EOF'
   ## Summary
   <!-- task-background.md からの背景要約 -->

   ## Requirements & Design
   - PRD: [PRD.md](./PRD.md)
   - System Design: [system-design.md](./system-design.md)
   - Test Specs: [automated-tests.md](./automated-tests.md) / [agentic-tests.md](./agentic-tests.md)

   ## QA & Test Evidence
   - Automated & Agentic Tests: **STATUS: PASS**
   - 詳細エビデンス: [qa-report-step5.md](./qa-report-step5.md) 参照
   - 最終コード監査: [review-step5.md](./review-step5.md) (Codex Review: PASS)

   ## Manual Verification Checklist (Human QA)
   以下はマージ前または本番リリース前に人間が手動で確認すべき項目です（manual-tests.md より抽出）:
   - [ ] <手動確認項目1>
   - [ ] <手動確認項目2>
   EOF
   ```
5. ユーザーに完了報告とPRのURLを提示して終了します。
