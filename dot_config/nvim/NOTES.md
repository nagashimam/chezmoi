## What this is

Phase1-B scope only: plain Neovim + LSP navigation (go-to-definition/references/hover/rename/code-action) for Vue/TS and chezmoi's Go-template dotfiles. No formatter/format-on-save, no which-key, no AI chat plugin (codecompanion.nvim) — those were explicitly deferred in the plan.

## LSP wiring: native APIs, not the old on_attach/setup() pattern

The original draft report used `lspconfig.ts_ls.setup({ on_attach = ..., ... })` (williamboman/mason-lspconfig + manual `.setup()` calls per server). As of Neovim 0.11+, that's no longer the recommended path — checked current (2026) guidance:

- Neovim 0.11 added native `vim.lsp.config()` / `vim.lsp.enable()`. `nvim-lspconfig` is still used, but now just as a source of default server definitions (its `lsp/*.lua` files), not as the thing you call `.setup()` on.
- `mason-lspconfig.nvim` (now under the `mason-org` GitHub org, not `williamboman`) has correspondingly shrunk: give it `ensure_installed`, and its `automatic_enable` option (on by default) calls `vim.lsp.enable()` for you once a server is installed. No more per-server `mason_lsp.setup({ ensure_installed = {...} })` + manual `lspconfig.X.setup()` combo.
- Keymaps are attached via a `LspAttach` autocmd instead of an `on_attach` callback passed into `.setup()` — same effect, current idiom.

So `lua/plugins/lsp.lua` overrides `ts_ls`/`vue_ls`/`html` via `vim.lsp.config(name, {...})` only where project-specific behavior is needed (Vue Hybrid Mode wiring, gotmpl filetypes); mason-lspconfig's `automatic_enable` handles turning the server on once installed.

## Carried over unchanged from the original draft

- Vue Hybrid Mode: `ts_ls` gets the `@vue/typescript-plugin` (handles TS inside `.vue` SFCs), `vue_ls` stays template/CSS-only. Same mechanism, just expressed via `vim.lsp.config` instead of `.setup()`.
- WSL2 clipboard fallback via `win32yank.exe`.

## One addition beyond the original draft

Chezmoi source files are named like `dot_zshrc.tmpl` / `config.toml.tmpl` — with no override, Neovim's filetype detection sees the outer `.tmpl` extension and loses syntax highlighting for the real format underneath. Added a `vim.filetype.add` pattern in `init.lua` that strips `.tmpl` and re-detects from what's left (so `.toml.tmpl` → `toml`, `.json.tmpl` → `json`), falling back to `gotmpl` (handled by the `html` LSP config in lsp.lua) only when there's no recognizable inner extension. Not in the original report — added because without it, editing chezmoi templates in this config would have been worse than before.

**Known gap**: chezmoi's `dot_` filename prefix convention (e.g. `dot_zshrc.tmpl`, no real extension after stripping `.tmpl`) can't be resolved to `sh` this way since there's no extension left to match on. Those files will fall through to `gotmpl`. Not fixed here — would need a chezmoi-specific filename-parsing rule, out of scope for "keep it simple."

## Not verified — I could not run anything

Per constraints, no Bash/execution was done. Nothing here has actually been opened in Neovim. Before trusting this:

1. `chezmoi apply` (or copy this tree to `~/.config/nvim` directly) so lazy.nvim can bootstrap.
2. Open Neovim on a `.vue` or `.ts` file inside a real project (needs `node_modules` / a `tsconfig.json` to be useful) and run `:LspInfo` — confirm `ts_ls` and/or `vue_ls` show as attached, not just installed.
3. Run `:checkhealth vim.lsp` and `:Mason` — confirm `ts_ls`, `vue_ls`, `html` installed via Mason without errors.
4. Open a chezmoi `.tmpl` file (e.g. `dot_config/herdr/config.toml.tmpl` from the Phase1-C track) and run `:set filetype?` — confirm it reports `toml`, not `tmpl` or `gotmpl`.
5. Test `gd`/`gr`/`K`/`<leader>lr`/`<leader>la` on an attached buffer.

If `ts_ls` doesn't pick up the Vue plugin on the very first run, it's because `vue-language-server` wasn't installed yet when `lsp.lua` first evaluated `mason-registry` — restart Neovim once after Mason finishes installing.

## Fixed after real-world testing (2026-09-08)

`herdr-context.lua`'s first version assumed `herdr pane neighbor` prints a bare
pane id as plain text. It doesn't — it prints JSON
(`{"result":{"neighbor":{"pane_id":"w1:p3", ...}}, "id":"cli:request"}`), and
the old code passed that whole JSON blob as the `pane_id` argument to
`herdr pane run`, which failed with `pane_not_found` (confirmed via an actual
error from the user's herdr session). Fixed to decode with `vim.json.decode`
and read `result.neighbor.pane_id`; also now checks for an `error` key in
both `pane neighbor` and `pane run` responses, since herdr can return an
application-level error with a JSON body even when the process exit code is 0.

**Still open**: what `pane neighbor` returns when there is no pane in the
requested direction (e.g. the current pane is already the rightmost one) has
not been observed — the keymap may need a friendlier message for that case
once it's seen in practice.

## Second real-world bug (2026-09-08): stale '</'> marks in a Visual-mode Lua mapping

Next test run hit `E5108: start_col must be less than or equal to end_col`
inside `nvim_buf_get_text`. Root cause: `'<`/`'>` are only updated when
Visual mode is actually *left* (Esc, an operator, etc.). A Lua function
bound via `vim.keymap.set("v", lhs, function() ... end)` runs while Neovim
is still internally in the visual selection, so `getpos("'<")`/`getpos("'>")`
returned marks from the *previous* visual selection, not the current one —
occasionally producing a start position after the end position.

Fixed by calling `:normal! <Esc>` (via `nvim_replace_termcodes`) at the top
of the keymap callback to force Neovim to leave Visual mode and set '</'>
to the current selection *before* reading them.

## Third real-world bug (2026-09-09): self-send when no neighbor pane exists

With the previous two bugs fixed, `<leader>cp` ran without erroring but
corrupted the buffer being edited: the payload text ("Context file: ... /
help / help") got spliced into the very buffer the selection was taken from.

Root cause: the user's herdr layout has Neovim running in the *rightmost*
pane, with no pane further to the right. In that situation, `herdr pane
neighbor --direction right` does **not** return an error — it falls back to
returning the current pane's own id as the "neighbor" (confirmed by this
run; previously only guessed at from the very first `pane_not_found` error's
JSON, where `neighbor.pane_id` equaled the already-`focused` pane). Since
nothing in the code checked for this, `herdr pane run <same-pane> <payload>`
sent the payload right back into the Neovim instance it came from, which
(being in Normal mode after the Esc fix) interpreted the incoming
bracketed-paste text as a mix of commands/inserted characters, corrupting
the buffer.

Fixed by comparing the resolved `target_pane` against `vim.env.HERDR_PANE_ID`
(the env var herdr sets for the pane Neovim is running in) and refusing to
send with a clear warning instead, if they match. This is a layout problem,
not just a code bug: for `<leader>cp` to do anything useful, an agent pane
(Claude Code, Codex, ...) needs to actually exist in the configured
direction relative to Neovim's pane. Rearrange the herdr workspace
accordingly, or change the hardcoded `"right"` in the keymap at the bottom
of the file to whatever direction is correct for your layout.
