-- Navigation keymaps adhering to navigation.md philosophy:
-- "Jump forward with ], and return back to previous location with [["
-- "[[ followed by ]] advances back forward in the jump list"

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- 1. Base Jump Navigation (Jump list)
-- [[ : Jump back (Ctrl-o)
-- ]] : Jump forward (Ctrl-i)
map("n", "[[", "<C-o>", "Jump back to previous location")
map("n", "]]", "<C-i>", "Jump forward in history")

-- 2. LSP Jumps (]D, ]t, ]i, ]r, ]d, ]e)
map("n", "]D", vim.lsp.buf.definition, "Jump to Definition")
map("n", "]t", vim.lsp.buf.type_definition, "Jump to Type Definition")
map("n", "]i", vim.lsp.buf.implementation, "Jump to Implementation")
map("n", "]r", vim.lsp.buf.references, "Jump to References")
map("n", "]d", function()
  vim.diagnostic.goto_next()
end, "Jump to Next Diagnostic (Error/Warn)")
map("n", "]e", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, "Jump to Next Error only")

-- 3. Quickfix & Buffer cycling
map("n", "]q", "<cmd>cnext<cr>", "Jump to Next Quickfix item")
map("n", "]b", "<cmd>bnext<cr>", "Jump to Next Buffer")
