return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>c", group = "Context / Herdr" },
        { "<leader>f", group = "Find (Fuzzy)" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP / Code" },
        { "<leader>p", group = "Preview" },
        { "]", group = "Next Jump" },
        { "[", group = "Prev / Jump back" },
      },
    },
  },
}
