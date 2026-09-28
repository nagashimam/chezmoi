vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.clipboard = "unnamedplus"

-- chezmoi source files keep their real extension before .tmpl (e.g. config.toml.tmpl).
-- Detect filetype from the inner extension so toml/json/etc. keep their own syntax;
-- only fall back to Go-template filetype (for the html LSP's gotmpl handling) when
-- no inner extension is recognized.
vim.filetype.add({
  pattern = {
    ["*.tmpl"] = function(path)
      local inner_ft = vim.filetype.match({ filename = path:gsub("%.tmpl$", "") })
      return inner_ft or "gotmpl"
    end,
  },
})

-- macOS: share yank/paste with the system clipboard using the native tools.
if vim.fn.has("mac") == 1 then
  vim.g.clipboard = {
    name = "macOS clipboard",
    copy = {
      ["+"] = "pbcopy",
      ["*"] = "pbcopy",
    },
    paste = {
      ["+"] = "pbpaste",
      ["*"] = "pbpaste",
    },
    cache_enabled = 0,
  }
-- WSL2: share yank/paste with the Windows clipboard.
elseif vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
end

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- Load navigation keymaps ([[ back, ]] forward, ] jumps)
require("navigation")

-- Phase 2: send visually-selected code to the adjacent herdr agent pane.
-- Not a lazy.nvim plugin spec, so it's required directly rather than placed
-- under lua/plugins/ (which lazy.setup("plugins") expects to be spec files).
require("herdr-context")
