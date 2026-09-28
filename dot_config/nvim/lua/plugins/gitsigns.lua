return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- navigation.md に準拠したジャンプキーマップ
        -- ]c : 次の変更箇所 (Git Hunk) へジャンプ
        vim.keymap.set("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, buffer = bufnr, desc = "Jump to Next Git Hunk" })

        -- Git操作系 (<leader>g...)
        vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Git Preview Hunk" })
        vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "Git Reset Hunk" })
        vim.keymap.set("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, desc = "Git Stage Hunk" })
        vim.keymap.set("n", "<leader>gu", gs.undo_stage_hunk, { buffer = bufnr, desc = "Git Undo Stage Hunk" })
      end,
    },
  },
}
