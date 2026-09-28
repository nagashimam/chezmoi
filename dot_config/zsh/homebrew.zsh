# Shared Homebrew setup for login and non-login interactive zsh sessions.
# Avoid `brew --prefix`: launching brew on every shell startup is needlessly slow.
typeset -U path fpath

if [[ -z ${HOMEBREW_PREFIX:-} || ! -x ${HOMEBREW_PREFIX}/bin/brew ]]; then
  for homebrew_prefix_candidate in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x ${homebrew_prefix_candidate}/bin/brew ]]; then
      export HOMEBREW_PREFIX=${homebrew_prefix_candidate}
      break
    fi
  done
  unset homebrew_prefix_candidate
fi

if [[ -n ${HOMEBREW_PREFIX:-} && -x ${HOMEBREW_PREFIX}/bin/brew ]]; then
  if (( ! ${path[(Ie)${HOMEBREW_PREFIX}/bin]} )); then
    eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv zsh)"
  fi

  path=("${HOMEBREW_PREFIX}/bin" "${HOMEBREW_PREFIX}/sbin" $path)
  if [[ -d ${HOMEBREW_PREFIX}/share/zsh/site-functions ]]; then
    fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
  fi
fi
