#!/usr/bin/env bash

set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    export PATH="/opt/homebrew/bin:$PATH"
  elif [ -x /usr/local/bin/brew ]; then
    export PATH="/usr/local/bin:$PATH"
  else
    echo "Homebrew was installed but its executable was not found." >&2
    exit 1
  fi
fi

brew_bin="$(command -v brew)"
eval "$("${brew_bin}" shellenv)"

formulae=(
  neovim herdr mise gh lazygit lazysql awscli wget
  zoxide fzf fd docker starship zsh-autosuggestions zsh-syntax-highlighting shellcheck
  graphviz
)
casks=(
  codex claude-code font-hackgen font-hackgen-nerd antigravity-cli ghostty
)

"${brew_bin}" info --formula "${formulae[@]}" >/dev/null
"${brew_bin}" info --cask "${casks[@]}" >/dev/null
"${brew_bin}" install --formula "${formulae[@]}"
"${brew_bin}" install --cask "${casks[@]}"

mise use -g node@lts
mise exec -- npm i -g skills
mise exec -- npx skills add herdrdev/herdr --skill herdr -g

herdr integration install codex
herdr integration install claude
herdr integration install antigravity-cli
