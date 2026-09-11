#!/usr/bin/env bash

if [ "$(uname -s)" != "Darwin" ]; then
  exit 0
fi

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install nvim codex claude herdr font-hackgen font-hackgen-nerd mise
brew install --cask antigravity-cli ghostty

mise use -g node@lts 
npm i -g skills
npx skills add herdrdev/herdr --skill herdr -g

herdr integration install codex
herdr integration install claude
herdr integration install antigravity-cli
