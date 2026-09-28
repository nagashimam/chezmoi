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
| `<leader>gg` | **Lazygit 起動** | **G**it **G**ui (lazygit) | ターミナル Lazygit をフロート表示 |
| `<leader>fe` | **ファイルエクスプローラー** | **F**ile **E**xplorer | snacks.explorer でファイルツリー表示 |

### Zsh側 (シェル)
- **インサートモード (viins)**:
  - `Ctrl+R` : コマンド履歴検索 (fzf)
  - `Ctrl+T` : カーソル位置へのファイルパス挿入 (fzf + fd)
- **ノーマルモード (vicmd)**:
  - `Space f f` : ファイル検索して `$EDITOR` で開く
  - `Space f g` : Grepして選択したファイルを `$EDITOR` で開く
  - `Space g b` : `git branch` をfzf選択して `git checkout`

---

## 3. 採用プラグイン: `folke/snacks.nvim`

プラグインごとの設定肥大化や重複を防ぎ、Neovimの周辺機能（ピッカー、エクスプローラー、通知、インデントガイド等）を統一エコシステムで管理するため、**`snacks.nvim`** を採用。

- **`Snacks.picker.files()`**: ファイル検索 (`<leader>ff`)
- **`Snacks.picker.grep()`**: Live Grep (`<leader>fg`)
- **`Snacks.picker.buffers()`**: バッファ切り替え (`<leader>fb`)
- **`Snacks.picker.recent()`**: 最近のファイル (`<leader>fr`)
- **`Snacks.picker.git_branches()`**: Gitブランチ切り替え (`<leader>gb`)
- **`Snacks.lazygit()`**: Lazygit起動 (`<leader>gg`)
- **`Snacks.explorer()`**: ファイルエクスプローラー (`<leader>fe`)

