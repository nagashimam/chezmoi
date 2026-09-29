#!/usr/bin/env bash
set -euo pipefail

HERDR_BIN="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
export HERDR_SOCKET_PATH="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"

# 元ペインのフォーカスを維持したまま右に分割
"$HERDR_BIN" pane split --direction right --no-focus >/dev/null 2>&1 || exit 1
# 元ペインと右にできた新ペインを入れ替え（新ペインが左側に配置される）
"$HERDR_BIN" pane swap --direction right >/dev/null 2>&1 || exit 1
# フォーカスを左側の新ペインへ移動
"$HERDR_BIN" pane focus --direction left >/dev/null 2>&1 || true
