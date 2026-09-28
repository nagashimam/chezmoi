return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    init = function()
      -- Enable rendering UML diagrams (PlantUML) in markdown previews
      vim.g.mkdp_preview_options = {
        uml = { server = "http://www.plantuml.com/plantuml" },
      }
      vim.g.mkdp_auto_close = 1
    end,
    keys = {
      { "<leader>pm", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown Preview Toggle" },
    },
  },
  {
    "weirongxu/plantuml-previewer.vim",
    ft = { "plantuml", "puml" },
    dependencies = {
      "tyru/open-browser.vim",
      "aklt/plantuml-syntax",
    },
    keys = {
      { "<leader>pu", "<cmd>PlantumlOpen<cr>", ft = { "plantuml", "puml" }, desc = "PlantUML Preview (Browser)" },
    },
  },
}
