-- Send the visually-selected text (with a file/line header) into the herdr
-- pane next to the current one -- typically where an AI agent (Claude Code,
-- Codex, etc.) is running.
--
-- Verified against https://herdr.dev/docs/cli-reference/ and confirmed by an
-- actual run (2026-09):
--   herdr pane neighbor --direction <dir> [--current]   -> JSON, not bare text
--   herdr pane run <pane_id> <text>                     -> bracketed-paste + Enter, atomic
--
-- CORRECTED (was wrong in the first draft): `pane neighbor` prints a JSON
-- response like:
--   {"result":{"neighbor":{"pane_id":"w1:p3", ...}, "type":"pane_neighbor"}, "id":"cli:request"}
-- The first version of this file passed the *entire* JSON blob as the
-- pane_id argument to `pane run`, which failed with `pane_not_found` because
-- herdr tried to look up a pane literally named after the whole JSON string.
-- Fixed by decoding with vim.json.decode and reading `result.neighbor.pane_id`.
--
-- herdr wraps errors as {"error":{"code":..., "message":...}, "id":...}
-- even when the process exit code is 0, so both layers are checked below.

local M = {}

local function run_herdr(args)
  return vim.system({ "herdr", unpack(args) }, { text = true }):wait()
end

--- @return string|nil pane_id, string|nil err
local function extract_neighbor_pane_id(stdout)
  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok or type(decoded) ~= "table" then
    return nil, "could not parse JSON from `herdr pane neighbor`: " .. tostring(stdout)
  end
  if decoded.error then
    return nil, decoded.error.message or vim.inspect(decoded.error)
  end
  local pane_id = decoded.result and decoded.result.neighbor and decoded.result.neighbor.pane_id
  if not pane_id then
    return nil, "no result.neighbor.pane_id in response: " .. tostring(stdout)
  end
  return pane_id
end

--- @param direction "left"|"right"|"up"|"down"
function M.send_selection_to_agent(direction)
  direction = direction or "right"

  if vim.env.HERDR_ENV ~= "1" then
    vim.notify("herdr-context: not running inside a herdr pane (HERDR_ENV unset)", vim.log.levels.WARN)
    return
  end

  local srow, scol = unpack(vim.fn.getpos("'<"), 2, 3)
  local erow, ecol = unpack(vim.fn.getpos("'>"), 2, 3)
  local lines = vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
  local body = table.concat(lines, "\n")
  local header = string.format("Context file: %s (L%d-L%d)\n", vim.fn.expand("%:p"), srow, erow)
  local payload = header .. body

  -- vim.system passes args as a list (no shell involved), so no escaping
  -- concerns even though `payload` may contain quotes/newlines.
  local neighbor = run_herdr({ "pane", "neighbor", "--direction", direction, "--current" })

  if neighbor.code ~= 0 then
    vim.notify(
      "herdr-context: `herdr pane neighbor` exited " .. neighbor.code .. ": " .. (neighbor.stderr or ""),
      vim.log.levels.ERROR
    )
    return
  end

  local target_pane, err = extract_neighbor_pane_id(neighbor.stdout)
  if not target_pane then
    vim.notify("herdr-context: " .. err, vim.log.levels.ERROR)
    return
  end

  -- CONFIRMED BY ACTUAL USE (2026-09-09): when there is no pane in the
  -- requested direction, `herdr pane neighbor` does NOT return an error --
  -- it falls back to returning the CURRENT pane's own id as "neighbor".
  -- Without this guard, `pane run` then pastes the payload straight back
  -- into this same Neovim instance (observed: it got fed in as literal
  -- keystrokes/paste, corrupting the buffer). Refuse to self-send instead.
  if target_pane == vim.env.HERDR_PANE_ID then
    vim.notify(
      "herdr-context: no pane found to the "
        .. direction
        .. " of this one (herdr returned this pane itself as the \"neighbor\") -- "
        .. "arrange an agent pane in that direction, or call send_selection_to_agent with a different direction.",
      vim.log.levels.WARN
    )
    return
  end

  local result = run_herdr({ "pane", "run", target_pane, payload })
  if result.code ~= 0 then
    vim.notify("herdr-context: `herdr pane run` exited " .. result.code .. ": " .. (result.stderr or ""), vim.log.levels.ERROR)
    return
  end

  -- herdr can report an application-level error inside JSON with exit code 0
  local ok, decoded = pcall(vim.json.decode, result.stdout)
  if ok and type(decoded) == "table" and decoded.error then
    vim.notify(
      "herdr-context: `herdr pane run` returned an error: " .. (decoded.error.message or vim.inspect(decoded.error)),
      vim.log.levels.ERROR
    )
  end
end

local function leave_visual_mode()
  -- '< / '> are NOT updated until Visual mode is actually left. A Lua
  -- function bound to a Visual-mode mapping runs while Vim is still
  -- internally "in" the visual selection (marks still hold the *previous*
  -- selection), so getpos("'<")/getpos("'>") return stale data unless we
  -- exit Visual mode ourselves first. This is what caused the observed
  -- "start_col must be less than or equal to end_col" crash: mismatched
  -- old-selection marks handed to nvim_buf_get_text.
  vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
end

vim.keymap.set("v", "<leader>cp", function()
  leave_visual_mode()
  M.send_selection_to_agent("right")
end, { desc = "Send selection to herdr agent pane (right)" })

return M
