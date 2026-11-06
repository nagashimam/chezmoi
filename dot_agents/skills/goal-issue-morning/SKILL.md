---
name: goal-issue-morning
description: 毎朝の勤務開始時に、今期の3つのゴールissue(sub-issue全階層)と関連PRの状況を確認し、今日やることを日本語で提案する。「おはよう」「今日何やる?」「朝のレビュー」「ゴールの状況」等で使う。Morning review of the quarterly goal issues, nested sub-issues and related PRs.
---

# Morning goal issue review

ユーザー(フロントエンドエンジニア)が今日何をすべきか決めるための朝のレビュー。読み取り専用で、更新してよいのはローカルキャッシュのみ。

## 設定

- Repo: `snkrdunk/snkrdunk-en`
- Goal issues: `12452`, `11258`, `6187`
- Cache dir(絶対パス): `~/.agents/skills/goal-issue-morning/cache/`
  - `state.json`: `{ "<issue|pr>#N": { title, state, labels, assignees, updated_at, fetched_at, summary, goal, parent, ...(PR: draft, reviewDecision, checks) } }`
  - `blockers.json`: 下記スキーマ
- 「自分」= `gh api user -q .login` のログイン名。
- **PR承認ルール(マージに必要な人間レビュアーの承認)**:
  - `#6187` 配下のタスク/PR: **`daisukeueta` と `yassuzu` の両名** の Approve が必須。
  - それ以外のタスク/PR: **`daisukeueta`** の Approve が必須。
  - **Botの除外**: Bot(例: `github-actions[bot]`, `coderabbitai[bot]`, `copilot` 等)によるレビュー・Approve は承認要件としてカウントしない。BotのApproveのみでマージを提案してはならない。

## 優先順位の原則

1. **自分が動くべきもの**を最優先: 自分宛てのレビュー依頼、自分のPRのCI失敗/changes requested、自分がassigneeの未完了issue。
2. 次に、`needs-human` のうち**実際に作業を止めているもの**(ラベルだけで判断せず、必要な判断/アクションと、何を止めているかを特定する)。
3. 次に、ブロックされていない着手可能な作業。
4. 期限・今期残り日数・進捗率(closed/total)も考慮する。

## 手順

### 1. 収集(軽量スキャン・毎回必須)

- `gh api graphql` で階層ごとにBFSする。1クエリで全階層をネストすると `MAX_NODE_LIMIT_EXCEEDED`(50万ノード)で失敗するため、1階層ずつ、20 issueを alias(`i123: issue(number:123){...}`)で1クエリにまとめる。ヘッダ `GraphQL-Features: sub_issues` を付ける。issueごとに `gh issue view` を回さない。取得項目: number, title, state, labels, assignees, updatedAt, `subIssues(first:100){totalCount pageInfo{hasNextPage} nodes{number}}`。`hasNextPage` が true なら続きを取る。
- 紐づくPRは `closedByPullRequestsReferences` だけでは「閉じる」関係しか拾えない。`timelineItems(itemTypes:[CONNECTED_EVENT,CROSS_REFERENCED_EVENT])` も併用してPR参照を拾う。
- 各PRについて state, isDraft, reviewDecision, statusCheckRollup, reviewRequests, updatedAt, および最新レビュアー・承認状態(`latestOpinionatedReviews` または `reviews` の `author.login` と `state`)を取る。BotのApproveと人間のApproveを区別できるようにする。
- PRのcloseとissueのcloseは連動すると仮定しない。
- 各子孫がどのゴール・親に属するかを保持する。
- 取得失敗(未認証、レート制限、権限不足)は黙って続行せず、レポート冒頭で「取得できなかった範囲」を明示する。

### 2. キャッシュ照合

- `state.json` を読む(無い/壊れていれば空として扱い、後で再作成)。
- 本文・コメント・PR説明の詳細取得は、次のいずれかの場合のみ: 要約が無い / GitHubの `updatedAt` がキャッシュより新しい。それ以外はキャッシュの要約を使う。(CI・レビュー状態は手順1で毎回取れるので期間による再取得は不要。)
- 詳細を読む優先対象: 自分に関係するもの、active な `needs-human`、前回から変化したもの、open、CI失敗、changes requested、親/他タスクをブロックしていそうなもの。
- closedで変化のないものは履歴を読まない。コメントは直近の要点(最新の依頼・決定・質問)だけ読む。足りない場合に限り最小限追加で読む。
- 前回との差分(state/labels/assignee/PR状態/CIの変化)を出せるよう、`state.json` には前回値を上書きする前に比較する。

### 3. 判定

- active `needs-human` ごとに: 必要な人間の判断/アクション、待っている人/もの、ブロックしている親・ゴール、待つ間にエージェントが安全にできる準備作業。
- **PRのマージ判定 & アクション提案**:
  - BotのApproveだけではマージ可能と判断しない。
  - マージを提案できる条件: open かつ non-draft、CIパス(statusCheckRollupが成功)、changes requestedなし、かつ**必須レビュアー全員のApprove完了**。
    - `#6187` 配下: `daisukeueta` と `yassuzu` の両方が APPROVED。
    - それ以外のゴール配下: `daisukeueta` が APPROVED。
  - 上記条件を満たした場合のみ「PRのマージ」を次のアクションとして提案する。
  - 承認が不足している場合: マージを提案せず、「〇〇へレビュー依頼」「〇〇のレビュー待ち(必要に応じ催促)」として提案する。
- ラベルが古い/曖昧/根拠なしの場合は、変更せず不確かさを報告する(目安: 14日以上更新がなく文脈上の依頼が無い)。

### 4. レポート(日本語、全体で約40行以内)

先頭に、取得失敗があればその旨。次にゴールごと(3つ)に:
- 全体状態(進捗 closed/total)と前回からの意味のある変化
- active blocker(子孫のIDを含む)
- 関連PRの状態(必須レビュアーの承認状況を含む)
- 次のアクション(承認要件を満たしたPRのマージ、未承認PRのレビュー依頼/待ち、CI修正、着手可能タスク等)

変化のないチケットは個別に列挙せず「変更なし(N件)」にまとめる。最後に、**最初にやるべきことを1つ**、理由つきで示す。`needs-human` が無ければその旨と、次の着手可能タスクを示す。

### 5. キャッシュ保存

- `state.json` を更新する。
- `blockers.json` を一時ファイル→rename で書く(英語キー、人間向け文面は日本語可)。work-registry.json は触らない。

```json
{
  "generated_at": "ISO8601",
  "blockers": [
    { "issue": "#123", "goal": "#12452", "path": ["#12452", "#200", "#123"],
      "needs_human_label": true, "human_action": "…", "blocks": ["#124"] }
  ],
  "candidates": [ { "issue": "#130", "updated_at": "ISO8601" } ]
}
```

`candidates` は open・未ブロック・着手可能なleafチケット。

## 出力の絞り込み(作業中のトークン節約)

作業中の集計出力でも、Open issueを全件表示しない。表示するのは `needs-human`、PRあり、直近7日以内に更新、のいずれかに該当するものだけ。残りは件数にまとめる。

## 制約

- GitHubのissue/PRの状態・ラベル・コメント・assignee・レビューは変更しない。
- コードは変更しない。サブエージェントも起動しない。
- 認証情報や無関係な個人情報をキャッシュしない。

## 登録メモ

このスキルが Skill 一覧に出ない場合、`~/.claude/skills/goal-issue-morning` へのシンボリックリンクが必要なことがある(`~/.agents/skills` だけでは読み込まれない環境がある)。

## 任意: goal-issue-autopilot 連携

`blockers.json` は `goal-issue-autopilot` への引き継ぎ用スナップショットであり、着手可否の証拠ではない(同スキルがGitHubの最新状態を再確認する)。作業中の管理は `cache/work-registry.json` で別管理されるため、上書きしない。
