return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      {
        "mason-org/mason-lspconfig.nvim",
        opts = {
          ensure_installed = {
            "vtsls",
            "vue_ls",
            "html",
            "cssls",
            "gopls",
            "lua_ls",
          },
        },
      },
    },
    config = function()
      local ok, mason_registry = pcall(require, "mason-registry")

      -- Helper to resolve @vue/typescript-plugin path safely
      local function get_vue_plugin_path()
        if ok and mason_registry.is_installed("vue-language-server") then
          return mason_registry
            .get_package("vue-language-server")
            :get_install_path() .. "/node_modules/@vue/language-server"
        end
        return ""
      end

      -- Vue Hybrid Mode configuration:
      -- vtsls handles TS/JS inside .vue SFCs via @vue/typescript-plugin
      vim.lsp.config("vtsls", {
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = get_vue_plugin_path(),
                  languages = { "vue" },
                  configNamespace = "typescript",
                  enableForWorkspaceTypeScriptVersions = true,
                },
              },
            },
          },
        },
      })

      -- vue_ls handles template and styles only (Hybrid mode)
      vim.lsp.config("vue_ls", {
        init_options = {
          vue = { hybridMode = true },
        },
      })

      -- HTML LSP (also supports chezmoi Go-template files)
      vim.lsp.config("html", {
        filetypes = { "html", "gotmpl", "gohtmltmpl" },
      })

      -- CSS LSP
      vim.lsp.config("cssls", {})

      -- Go LSP
      vim.lsp.config("gopls", {})

      -- Lua LSP (configured alongside lazydev.nvim)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = {
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      -- Keymaps and Format on Save on LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
          end

          -- Jump mappings are defined centrally in navigation.lua (]D, ]t, ]i, ]r, ]d, ]e)
          -- Code action mappings (<leader>l...)
          map("K", vim.lsp.buf.hover, "Hover Document")
          map("<leader>lr", vim.lsp.buf.rename, "Rename Symbol")
          map("<leader>la", vim.lsp.buf.code_action, "Code Action")

          -- Manual Format
          map("<leader>lf", function()
            vim.lsp.buf.format({ timeout_ms = 1000 })
          end, "Format Buffer")

          -- Format & Save
          map("<leader>ls", function()
            vim.lsp.buf.format({ timeout_ms = 1000 })
            vim.cmd.write()
          end, "Format & Save")

          -- Format on Save (autocmd)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
                timeout_ms = 1000,
              })
            end,
          })
        end,
      })
    end,
  },
}
