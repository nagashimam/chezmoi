# Fuzzy Finding 設計方針

## 1. 概要と背景
Zsh (シェル) と Neovim (エディタ) の間で行き来する際の認知摩擦を最小化するため、ファジー検索のキーバインドとメンタルモデルを統一する。

Neovim側では `<leader>f` (Find) および `<leader>g` (Git) をプレフィックスとし、Zsh側でも Vi モードのノーマルモード (vicmd) を活用して同様のキー操作で呼び出せる「プランA」を採用する。

---

## 2. キーバインド体系

### Neovim側 (<leader> = Space)
| キーバインド | アクション | 英語・メンタルモデル | 備考 |
| :--- | :--- | :--- | :--- |
| `<leader>ff` | **ファイル名検索** | **F**ind **F**iles | 最頻出・`f`連打で最速 |
| `<leader>fg` | **全文検索 (Grep)** | **F**ind **G**rep / Live Grep | ripgrepでプロジェクト内検索 |
| `<leader>fb` | **バッファ一覧** | **F**ind **B**uffers | 開いているファイルの切り替え |
| `<leader>fr` | **最近開いたファイル** | **F**ind **R**ecent files | 直近の作業ファイル一覧 |
| `<leader>gb` | **Gitブランチ検索** | **G**it **B**ranches | ブランチ一覧と切り替え (checkout) |

### Zsh側 (シェル)
- **インサートモード (viins)**:
  - `Ctrl+R` : コマンド履歴検索 (fzf)
  - `Ctrl+T` : カーソル位置へのファイルパス挿入 (fzf + fd)
- **ノーマルモード (vicmd)**:
  - `Space f f` : ファイル検索して `$EDITOR` で開く
  - `Space f g` : Grepして選択したファイルを `$EDITOR` で開く
  - `Space g b` : `git branch` をfzf選択して `git checkout`

---

## 3. プラグイン非依存の抽象化 (選定を保留できる理由)

現代の主要な3つのファジーファインダー (`fzf-lua`, `snacks.picker`, `telescope.nvim`) はすべて同等のインターフェースを備えており、キーバインド設計に影響を与えずに後から選択・差し替えが可能。

| 対象 | `fzf-lua` | `snacks.picker` | `telescope.builtin` |
| :--- | :--- | :--- | :--- |
| ファイル | `require("fzf-lua").files()` | `Snacks.picker.files()` | `require("telescope.builtin").find_files()` |
| 全文検索 | `require("fzf-lua").live_grep()` | `Snacks.picker.grep()` | `require("telescope.builtin").live_grep()` |
| バッファ | `require("fzf-lua").buffers()` | `Snacks.picker.buffers()` | `require("telescope.builtin").buffers()` |
| 最近のファイル | `require("fzf-lua").oldfiles()` | `Snacks.picker.recent()` | `require("telescope.builtin").oldfiles()` |
| Gitブランチ | `require("fzf-lua").git_branches()` | `Snacks.picker.git_branches()` | `require("telescope.builtin").git_branches()` |

※プラグイン自体の選定は、UI/モーダル、通知機能、ファイルエクスプローラーなど、Neovim全体の周辺ツール構成の検討と合わせて決定する。
