-- LSP only. No formatter, no which-key, no AI chat plugin here by design (Phase1-B scope).
return {
  {
    "neovim/nvim-lspconfig", -- supplies default server configs consumed by vim.lsp.enable()
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      {
        "mason-org/mason-lspconfig.nvim",
        opts = {
          ensure_installed = { "ts_ls", "vue_ls", "html" },
          -- automatic_enable defaults to true: installed servers are vim.lsp.enable()'d for us.
        },
      },
    },
    config = function()
      -- Vue "Hybrid Mode": ts_ls handles the <script> block of .vue SFCs via the
      -- @vue/typescript-plugin; vue_ls (Volar) only handles template/CSS. Requires
      -- the vue-language-server package mason installs alongside vue_ls.
      local ok, mason_registry = pcall(require, "mason-registry")
      local vue_language_server_path = ""
      if ok and mason_registry.is_installed("vue-language-server") then
        vue_language_server_path = mason_registry
          .get_package("vue-language-server")
          :get_install_path() .. "/node_modules/@vue/language-server"
      end

      vim.lsp.config("ts_ls", {
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = vue_language_server_path,
              languages = { "vue" },
            },
          },
        },
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      })

      vim.lsp.config("vue_ls", {
        init_options = {
          vue = { hybridMode = true },
        },
      })

      -- Reuse the html server for Go-template dotfiles (chezmoi's *.tmpl files) so
      -- {{ }} braces don't get mangled by plain HTML matching/indent rules.
      vim.lsp.config("html", {
        filetypes = { "html", "gotmpl", "gohtmltmpl" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
          end
          map("gd", vim.lsp.buf.definition, "Goto Definition")
          map("gr", vim.lsp.buf.references, "Goto References")
          map("K", vim.lsp.buf.hover, "Hover Document")
          map("<leader>lr", vim.lsp.buf.rename, "Rename Symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code Action")
        end,
      })
    end,
  },
}
