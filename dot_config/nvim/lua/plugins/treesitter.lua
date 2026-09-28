return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "vue",
        "typescript",
        "javascript",
        "tsx",
        "html",
        "css",
        "scss",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "bash",
        "go",
        "markdown",
        "markdown_inline",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
