# herdr config — verification notes

## File
`dot_config/herdr/config.toml` (plain TOML, **not** a chezmoi `.tmpl`).

herdr is a single cross-platform Rust binary and this file only sets
UI/pane-management preferences (prefix key, theme, sidebar, mouse, toast
delivery, session resume) — nothing here differs between macOS and WSL2,
so there's no `is_mac`/`is_wsl` branching to template. If OS-specific
values become necessary later (e.g. a different `[terminal] default_shell`
per host), convert to `config.toml.tmpl` at that point.

## Verified against real docs (https://herdr.dev/docs/config-reference/,
https://herdr.dev/docs/configuration/)
- `keys.prefix` (string, default `"ctrl+b"`) — real field, kept as `"ctrl+t"` per the user's original preference.
- `theme.name` (string, default `"catppuccin"`) — real, and `"catppuccin"` is the documented default value itself, so it's a safe known-good value.
- `ui.mouse_capture` (bool, default `true`) — **this is the real field name**. The original draft report used `mouse_support`, which does not appear to exist — corrected here.
- `ui.sidebar_width` / `sidebar_min_width` / `sidebar_max_width` (ints, defaults 26/18/36) — real.
- `ui.sidebar_start_collapsed` (bool, default `false`) — real. The original draft's `auto_hide_sidebar` field name does not appear to exist — corrected here. (There's also `ui.sidebar_collapsed_mode`, an enum default `"compact"`, left unset/default.)
- `ui.toast.delivery` (enum, default `"off"`) — real; valid values confirmed as `"herdr"`, `"terminal"`, `"system"`, `"off"`. Set to `"system"` per original intent.
- `session.resume_agents_on_restore` (bool, default `true`) — real, matches original draft exactly.
- Config lives at `~/.config/herdr/config.toml`; `herdr --default-config` dumps current defaults; `herdr server reload-config` hot-reloads.

## Unverified / best-guess (flagged inline in the file)
- `theme.auto_switch`, `theme.dark_name`, `theme.light_name` exist per the config-reference fetch, but the actual catalog of built-in theme names (beyond the documented default `"catppuccin"`) was not confirmed — so no light-variant theme name is set. Left commented out with a note to check `herdr --default-config` before enabling.

## Corrections vs. the original Gemini-drafted report
| Original (unverified) | Corrected (verified) |
|---|---|
| `ui.mouse_support` | `ui.mouse_capture` |
| `ui.auto_hide_sidebar` | `ui.sidebar_start_collapsed` |

Everything else the original draft used for basic UI (`keys.prefix`, `theme.name`/`dark_name`, `ui.sidebar_width`, `ui.toast.delivery`, `session.resume_agents_on_restore`) checked out as real fields.

Not included in this file (out of scope for Phase 1-C): `[[keys.command]]` pane-launch shortcuts for Browsh/lazygit (deferred tools), and any AI-agent integration (Phase 2).
