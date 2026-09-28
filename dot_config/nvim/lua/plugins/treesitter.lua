return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
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
    end,
  },
}
