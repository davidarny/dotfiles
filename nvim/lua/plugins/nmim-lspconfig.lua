local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local stylelint_filtypes = {
  "css",
  "scss",
  "less",
  "postcss",
}

local stylelint_settings = {
  stylelintplus = {
    autoFixOnSave = true,
    validateOnSave = true,
    validateOnType = true,
    autoFixOnFormat = true,
  },
}

return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        html = {
          filetypes = { "html", "php" },
          settings = {
            html = {
              suggest = {
                completion = {
                  emmet = true,
                  enable = true,
                },
              },
            },
          },
        },
        jsonls = {},
        cssls = {},
        phpactor = {},
        css_variables = {},

        stylelint_lsp = {
          filetypes = stylelint_filtypes,
          settings = stylelint_settings,
        },
      },

      setup = {
        html = function(_, opts)
          opts.capabilities = capabilities
        end,

        cssls = function(_, opts)
          opts.capabilities = capabilities
        end,

        jsonls = function(_, opts)
          opts.capabilities = capabilities
        end,
      },
    },
  },
}
