return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      local ts = require("nvim-treesitter")

      ts.setup()

      local parsers = {
        "vue",
        "typescript",
        "javascript",
        "tsx",
        "html",
        "css",
        "scss",
        "json",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "bash",
        "go",
        "markdown",
        "markdown_inline",
      }

      local installed = ts.get_installed()
      local to_install = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, parsers)

      if #to_install > 0 then
        ts.install(to_install)
      end

      -- Neovim 0.12 標準の Treesitter ハイライト & インデント設定
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- navigation.md に準拠した構造ジャンプ (nvim-treesitter-textobjects)
      local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
      if ok then
        ts_configs.setup({
          textobjects = {
            move = {
              enable = true,
              set_jumps = true, -- jumplist に記録して [[ で戻れるようにする
              goto_next_start = {
                ["]f"] = { query = "@function.outer", desc = "Jump to Next Function" },
                ["]a"] = { query = "@parameter.inner", desc = "Jump to Next Parameter/Argument" },
                ["]k"] = { query = "@block.outer", desc = "Jump to Next Block/Scope" },
                ["]T"] = { query = "@tag.outer", desc = "Jump to Next HTML/Vue Tag" },
              },
            },
          },
        })
      end
    end,
  },
}
