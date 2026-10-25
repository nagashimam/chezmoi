#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
temp_root=$(mktemp -d)
trap 'rm -rf "${temp_root}"' EXIT

mkdir -p "${temp_root}/.config/zsh" "${temp_root}/.cache"
cp "${repo_dir}/dot_zshenv" "${temp_root}/.zshenv"
cp "${repo_dir}/dot_zprofile" "${temp_root}/.zprofile"
cp "${repo_dir}/dot_zshrc" "${temp_root}/.zshrc"
cp "${repo_dir}/dot_config/zsh/homebrew.zsh" "${temp_root}/.config/zsh/homebrew.zsh"
cp "${repo_dir}/dot_config/zsh/zshenv.zsh" "${temp_root}/.config/zsh/zshenv.zsh"
cp "${repo_dir}/dot_config/zsh/zshrc.zsh" "${temp_root}/.config/zsh/zshrc.zsh"
cp "${repo_dir}/dot_config/starship.toml" "${temp_root}/.config/starship.toml"

zsh -n "${temp_root}/.zshenv"
zsh -n "${temp_root}/.zprofile"
zsh -n "${temp_root}/.zshrc"
zsh -n "${temp_root}/.config/zsh/zshenv.zsh"
zsh -n "${temp_root}/.config/zsh/zshrc.zsh"
render_install_script() {
  local target_os="$1"
  local tmpl="${repo_dir}/run_once_before_00-install-packages.sh.tmpl"
  if command -v chezmoi >/dev/null 2>&1; then
    chezmoi execute-template --override-data "{\"chezmoi\":{\"os\":\"${target_os}\"}}" <"${tmpl}"
  else
    awk -v os="${target_os}" '
      /^\{\{ if eq \.chezmoi\.os "darwin" -\}\}/ { mode = "darwin"; next }
      /^\{\{ else if eq \.chezmoi\.os "linux" -\}\}/ { mode = "linux"; next }
      /^\{\{ end -\}\}/ { mode = ""; next }
      mode == "" || mode == os { print }
    ' "${tmpl}"
  fi
}

for target_os in darwin linux; do
  rendered_script="${temp_root}/install-packages-${target_os}.sh"
  render_install_script "${target_os}" >"${rendered_script}"
  bash -n "${rendered_script}"
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${rendered_script}"
  fi
done

if [[ "$(uname -s)" == "Darwin" ]]; then
  ZDOTDIR="${temp_root}" HOME="${temp_root}" XDG_CONFIG_HOME="${temp_root}/.config" \
    zsh -dfic '(( $+commands[brew] )) && (( $+commands[fd] ))'
  ZDOTDIR="${temp_root}" HOME="${temp_root}" XDG_CONFIG_HOME="${temp_root}/.config" \
    zsh -dlfc '(( $+commands[brew] )) && (( $+commands[fd] ))'
else
  ZDOTDIR="${temp_root}" HOME="${temp_root}" XDG_CONFIG_HOME="${temp_root}/.config" \
    zsh -dfic '(( $+commands[fd] ))'
  ZDOTDIR="${temp_root}" HOME="${temp_root}" XDG_CONFIG_HOME="${temp_root}/.config" \
    zsh -dlfc '(( $+commands[fd] ))'
fi
ZDOTDIR="${temp_root}" HOME="${temp_root}" XDG_CONFIG_HOME="${temp_root}/.config" \
  zsh -dfic '[[ $(bindkey -M viins "^X?") == *zsh-key-help ]] && [[ $(bindkey -M vicmd "^X?") == *zsh-key-help ]]'

git init -q "${temp_root}/fd-fixture"
printf 'ignored\n' >"${temp_root}/fd-fixture/.gitignore"
touch "${temp_root}/fd-fixture/ignored" "${temp_root}/fd-fixture/visible"
fd_result=$(cd "${temp_root}/fd-fixture" && fd --type f --type d --follow --strip-cwd-prefix)
[[ ${fd_result} == visible ]]
