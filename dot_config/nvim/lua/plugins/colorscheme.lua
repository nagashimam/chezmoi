return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night", -- matches Ghostty "TokyoNight Night"
      transparent = true, -- inherit Ghostty background opacity (0.80)
      styles = {
        sidebars = "transparent",
        floats = "transparent",
        comments = { italic = false },
      },
      on_highlights = function(hl, c)
        -- コントラストを高めたコメント色（デフォルト: #565f89 -> #899bb5）
        hl.Comment = { fg = "#899bb5", italic = false }
        hl["@comment"] = { fg = "#899bb5", italic = false }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
