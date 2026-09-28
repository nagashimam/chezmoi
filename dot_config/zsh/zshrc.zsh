[[ -o interactive ]] || return

# Homebrew may not have been initialised when this is a non-login shell.
if [[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/homebrew.zsh ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/homebrew.zsh"
fi

typeset -U path fpath
path=("$HOME/.local/bin" "$HOME/.docker/bin" $path)
if [[ -d $HOME/.docker/completions ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=50000
# SHARE_HISTORY already appends and imports commands.  Do not combine it with
# INC_APPEND_HISTORY or INC_APPEND_HISTORY_TIME, which use incompatible timing.
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS
unsetopt INC_APPEND_HISTORY INC_APPEND_HISTORY_TIME

bindkey -v
KEYTIMEOUT=10
unsetopt FLOW_CONTROL

if (( $+commands[nvim] )); then
  export EDITOR=nvim VISUAL=nvim
else
  export EDITOR=vi VISUAL=vi
fi

zmodload -i zsh/complist
autoload -Uz compinit
zsh_cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
if [[ ! -d ${zsh_cache_dir} ]]; then
  mkdir -p "${zsh_cache_dir}"
fi
compinit -d "${zsh_cache_dir}/zcompdump-${ZSH_VERSION}"
unset zsh_cache_dir

zstyle ':completion:*' completer _complete _match _ignored _approximate
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}'
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' menu select=2
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B-- %d --%b'
zstyle ':completion:*:cd:*' tag-order local-directories path-directories directory-stack
if [[ -n ${LS_COLORS:-} ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi
bindkey -M viins '^I' complete-word
bindkey -M vicmd '^I' complete-word

unsetopt COMPLETE_ALIASES
alias ga='git add'
alias gs='git status'
alias nr='npm run'

if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

bindkey -M viins '^P' history-search-backward
bindkey -M viins '^N' history-search-forward
bindkey -M vicmd '^P' history-search-backward
bindkey -M vicmd '^N' history-search-forward
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M vicmd '^R' history-incremental-search-backward

autoload -Uz edit-command-line
zle -N edit-command-line
autoload -Uz _complete_help _history_complete_word _most_recent_file _next_tags
zle -C complete-help complete-word _complete_help
zle -C history-complete-word complete-word _history_complete_word
zle -C most-recent-file complete-word _most_recent_file
zle -C next-tags complete-word _next_tags

# A compact, built-in alternative to a which-key menu.  It deliberately uses
# ZLE's message area, so it has no startup cost or additional dependency.
zsh-key-help() {
  zle -M $'Zsh shortcuts — Esc: normal mode | i/a: insert mode\n  Ctrl-P / Ctrl-N  prefix history search    Ctrl-R  history search\n  Ctrl-T  fd + fzf file search (.gitignore respected)\n  Ctrl-F  accept suggestion    Ctrl-Q  keep command and start a new line\n  Ctrl-X Ctrl-E  edit buffer in $EDITOR\n  Ctrl-X h  completion help    Ctrl-X n  next completion group\n  Ctrl-X m  most recent file   Ctrl-X /  history completion\n  Ctrl-X ?  show this help'
}
zle -N zsh-key-help

for zle_keymap in viins vicmd; do
  bindkey -M "${zle_keymap}" '^X^E' edit-command-line
  bindkey -M "${zle_keymap}" '^Q' push-line
  bindkey -M "${zle_keymap}" '^Xh' complete-help
  bindkey -M "${zle_keymap}" '^Xn' next-tags
  bindkey -M "${zle_keymap}" '^Xm' most-recent-file
  bindkey -M "${zle_keymap}" '^X/' history-complete-word
  bindkey -M "${zle_keymap}" $'\C-x?' zsh-key-help
done
unset zle_keymap

if (( $+commands[fd] )); then
  export FZF_CTRL_T_COMMAND='fd --type f --type d --follow --strip-cwd-prefix'
fi
if [[ -t 0 && -t 1 ]]; then
  for fzf_key_bindings in \
    "${HOMEBREW_PREFIX:-}/opt/fzf/shell/key-bindings.zsh" \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh; do
    if [[ -r ${fzf_key_bindings} ]]; then
      source "${fzf_key_bindings}"
      break
    fi
  done
fi
unset fzf_key_bindings

PROMPT='%1~ %# '
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

for autosuggestions_script in \
  "${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -r ${autosuggestions_script} ]]; then
    source "${autosuggestions_script}"
    break
  fi
done
unset autosuggestions_script
if (( $+widgets[autosuggest-accept] )); then
  bindkey -M viins '^F' autosuggest-accept
else
  bindkey -M viins '^F' forward-char
fi

for syntax_highlighting_script in \
  "${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r ${syntax_highlighting_script} ]]; then
    source "${syntax_highlighting_script}"
    break
  fi
done
unset syntax_highlighting_script
