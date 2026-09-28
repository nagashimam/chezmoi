# Zsh configuration

This directory contains the Zsh configuration managed by chezmoi. It provides
a Vi-oriented interactive shell for macOS and remains usable on WSL2 when
optional tools are absent.

## File layout

- `zshenv.zsh` is sourced by `~/.zshenv`. It only adds mise shims to `path`.
  It must remain safe for every Zsh invocation: no external commands, output,
  prompt setup, or interactive-only options.
- `homebrew.zsh` is sourced by `~/.zprofile` and interactive shells. It finds
  a valid Homebrew prefix, initializes its environment only when needed, and
  adds its completion directory to `fpath`.
- `zshrc.zsh` is sourced by `~/.zshrc` and contains all interactive behavior:
  history, completion, key bindings, integrations, prompt, and plugins.
- `../starship.toml` configures the Starship prompt with ASCII-only symbols so
  it works with the configured HackGen font without requiring Nerd Font icons.

`dot_zshenv` and `dot_zshrc` are mandatory Zsh entry points. Keep them as
thin source wrappers; put functional Zsh settings in this directory.

## Configuration rules

- Preserve startup order in `zshrc.zsh`: PATH and `fpath`, history, Vi mode,
  completion, mise/zoxide, key bindings and fzf, Starship, autosuggestions,
  then syntax highlighting. Load `zsh-syntax-highlighting` last.
- Use `typeset -U path fpath` whenever adding path entries. Do not call
  `brew --prefix` during startup; reuse `HOMEBREW_PREFIX`.
- Guard optional executables with `(( $+commands[name] ))`, readable files
  with `[[ -r path ]]`, and directories with `[[ -d path ]]`. This keeps a
  missing optional dependency from breaking startup.
- Keep `SHARE_HISTORY` with `EXTENDED_HISTORY`; do not enable
  `INC_APPEND_HISTORY` or `INC_APPEND_HISTORY_TIME`, which conflict with its
  history-write behavior.
- Keep full `compinit` permission checks. Do not replace it with `compinit -C`
  merely to optimize startup time.
- Keep `unsetopt FLOW_CONTROL` while `Ctrl+Q` is bound to `push-line`.

## Interactive behavior

- The editor uses `bindkey -v`; bindings are installed in both `viins` and
  `vicmd` unless they are deliberately insert-only.
- `Ctrl+P` and `Ctrl+N` search history by the current prefix. `Ctrl+R` uses
  fzf when it is available and otherwise uses Zsh incremental history search.
- `Ctrl+T` uses fzf and
  `fd --type f --type d --follow --strip-cwd-prefix`. fd's normal ignore rules
  must remain enabled so file selection respects `.gitignore`.
- `Ctrl+X` then `?` displays the shortcut reference. Keep it updated whenever
  a user-facing binding changes.
- `Ctrl+F` accepts an autosuggestion when the plugin is loaded and otherwise
  retains Zsh's `forward-char` behavior.

## Dependencies

Every new Zsh dependency must be added to
`_run_once_before_00-install-packages.sh`. Formulae and casks are separate,
and their names are validated before installation. The current configuration
optionally integrates mise, zoxide, fzf, fd, Starship,
zsh-autosuggestions, and zsh-syntax-highlighting.

## Validation and applying changes

Run the configuration checks after changing these files:

```sh
bash tests/zsh-config-check.sh
git diff --check
```

The check performs syntax validation, verifies login and non-login interactive
startup, verifies the help binding, and confirms that fd respects `.gitignore`.

Apply changed shell files with chezmoi, then open a new shell or run
`exec zsh -l`:

```sh
chezmoi apply ~/.zshenv ~/.zprofile ~/.zshrc ~/.config/zsh ~/.config/starship.toml
```
