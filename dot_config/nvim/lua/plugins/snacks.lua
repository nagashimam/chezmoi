return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- 段階的に有効化可能なモジュール群
      -- ここではまずピッカー (Fuzzy Finder) と基本機能を有効化
      picker = {
        enabled = true,
        auto_close = true,
        jump = { close = true },
        sources = {
          explorer = {
            auto_close = true,
            jump = { close = true },
          },
        },
      },
      explorer = {
        enabled = true,
        auto_close = true,
      },
      lazygit = { enabled = true },
      notifier = { enabled = true },
      indent = { enabled = true },
    },
    keys = {
      -- Fuzzy Finding (<leader>f / <leader>g) - fuzzy-finding.md に準拠
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Find Grep (Live Grep)",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Find Buffers",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Find Recent Files",
      },
      {
        "<leader>gb",
        function()
          Snacks.picker.git_branches()
        end,
        desc = "Git Branches",
      },
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },

      -- エクスプローラー（ファイルツリー）
      {
        "<leader>fe",
        function()
          Snacks.explorer()
        end,
        desc = "File Explorer",
      },
    },
  },
}
