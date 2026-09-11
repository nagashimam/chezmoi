# Ghostty config — verification notes

## Verified against official sources
- **`intl_yen` is a real physical key**, defined in `ghostty-org/ghostty`'s
  `src/input/key.zig`. It's the dedicated ¥ key on JIS keyboards (sits
  between `=` and Backspace) — a distinct physical key, not `alt`+something.
  This corrects the earlier draft plan's `alt+intl_yen=text:\\`; the `alt+`
  prefix isn't needed.
- **`text:` action syntax**: confirmed on ghostty.org/docs/config/keybind —
  uses Zig string-literal escaping (e.g. `text:\x15` = Ctrl-U). `\\` is the
  correct escape for one literal backslash.
- Ghostty's docs pages don't publish a full physical-key-name list inline;
  they point to the source (`key.zig`) as the source of truth. `intl_yen`
  was confirmed there, not just assumed from the earlier draft.

## Carried over without independent verification
- `theme = catppuccin-mocha` — commonly known as a bundled Ghostty theme
  name, but I did not fetch a live `ghostty +list-themes` output to confirm
  it ships in the current version. Low risk (Ghostty just errors/ignores an
  unknown theme name), but check it.
- Font: switched to `HackGen Console` at the user's request (yuru7/HackGen,
  https://github.com/yuru7/HackGen/releases/tag/v2.10.0). Verified via the
  project README that "Console" is the terminal-recommended variant (it
  forces ambiguous-width symbols to half-width to avoid column misalignment)
  and that `brew install --cask font-hackgen` is the current install path
  (added to `phase1-install.sh`). NOT independently verified: the exact
  installed family name Ghostty will see (assumed `HackGen Console` matching
  the README's variant name) — confirm with `fc-list | grep -i hackgen` or
  `ghostty +list-fonts | grep -i hackgen` after installing, and adjust
  `font-family` if the reported name differs.

## No OS branching needed (yet)
No genuine macOS vs. WSL2 difference was identified for this file's current
scope (font/theme/window/JIS keybind) — Ghostty auto-detects the rendering
backend per platform. The file is kept as `config.tmpl` for consistency with
the rest of the chezmoi source tree, but it currently contains zero template
directives. If it stays this way through Phase 3 (WSL2 rollout), consider
renaming it to a plain `dot_config/ghostty/config` to avoid implying
templating logic that isn't there.

## How to validate after `chezmoi apply`
1. `ghostty +list-keybinds` — confirms the `intl_yen` binding registered and
   lets you cross-check `intl_yen` is spelled/recognized correctly on your
   installed version.
2. `ghostty +list-themes | grep catppuccin` — confirms the theme name exists
   before relaunching.
3. Relaunch Ghostty and press the physical ¥ key in a shell prompt — it
   should insert a literal `\` instead of `¥`. If Ghostty shows a config
   error banner/toast on launch, the config failed to parse — check for
   typos first.
