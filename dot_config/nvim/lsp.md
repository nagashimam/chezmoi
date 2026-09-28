# LSP 設定方針

## 1. 概要と対象言語
対象技術スタック：**Vue.js, TypeScript / JavaScript, HTML / CSS, Go**

Neovim 0.11+ のネイティブ LSP 機構 (`vim.lsp.config` / `vim.lsp.enable`) をベースとし、`mason.nvim` + `mason-lspconfig.nvim` の `automatic_enable` を利用してミニマルかつ堅牢に管理する。

---

## 2. 採用LSPサーバー一覧

| 言語 / 用途 | サーバー名 (`mason-lspconfig`) | 役割と設定詳細 | 状態 |
| :--- | :--- | :--- | :--- |
| **TypeScript / JS / Vue (Script)** | `vtsls` | 高速・高機能なTSサーバー。Vue Hybrid Modeプラグイン (`@vue/typescript-plugin`) を介して `.vue` SFC 内の `<script>` も担当 | 採用 |
| **Vue (Template / CSS)** | `vue_ls` | Volar (Hybrid Mode 有効)。テンプレートと CSS 領域のみを担当 | 採用 |
| **HTML / Template** | `html` | HTMLファイルおよび chezmoi の Go-template (`.tmpl`, `gotmpl`) の補完・構文解析 | 採用 |
| **CSS / SCSS** | `cssls` | `<style>` タグや `.css` ファイル内の補完・検証 | 採用 |
| **Go** | `gopls` | Go言語公式LSP。補完、定義ジャンプ、import 自動管理 | 採用 |
| **Linter / Formatter** | `eslint` (または `biome`) | LSP 経由での lint エラー検出および自動フォーマット | 採用 |

---

## 3. フォーマット方針 (Format on Save & 手動実行)

- **Format on Save**:
  - `BufWritePre` の autocmd で LSP フォーマット (`vim.lsp.buf.format()`) を実行。
  - 複数 LSP がアタッチされている場合（例: `vtsls` と `eslint`）、競合を防ぐためフォーマッターとして実行するサーバーをフィルタリング、または優先順位を設定する。
- **手動実行 / 保存**:
  - `<leader>lf` : 保存せずに LSP 整形のみ実行
  - `<leader>ls` : **LSP 整形を実行してから保存**（フォーマット即保存）

---

## 4. キーバインド

操作系は「ジャンプ系（`]` 始まり）」と「コード操作系（`<leader>l...`）」に綺麗に分離し、Herdr や Zsh との衝突を防止する。

### コード操作 (<leader>l... = LSP)
| キーバインド | アクション | 説明 |
| :--- | :--- | :--- |
| `K` | **Hover** | カーソル位置の型情報・ドキュメントをフロート表示 |
| `<leader>lr` | **Rename** | シンボルのプロジェクト横断リネーム |
| `<leader>la` | **Code Action** | コードアクション（quickfix、import補完等） |
| `<leader>lf` | **Format** | LSP によるコード整形（保存なし） |
| `<leader>ls` | **Format & Save** | LSP によるコード整形を実行してそのまま保存 |

### ジャンプ系
ジャンプ系はすべて `navigation.md` のルール（`]` で前進、`[[` で戻る）に従う：
- `]D` : 定義元へジャンプ (Definition)
- `]t` : 型定義へジャンプ (Type definition)
- `]i` : 実装へジャンプ (Implementation)
- `]r` : 参照一覧へジャンプ (References)
- `]d` : 次のエラー・警告へジャンプ (Diagnostic)
- `]e` : 次の「エラーのみ」へジャンプ (Error only, warning無視)
