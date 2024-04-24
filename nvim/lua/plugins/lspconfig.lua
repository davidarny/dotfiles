return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      -- inlay_hints = { enabled = true },
      ---@diagnostic disable-next-line: missing-fields
      servers = {
        -- TODO: enable when using project withg typescript v5.4
        -- tsserver = {
        --   settings = {
        --     typescript = {
        --       implementationsCodeLens = { enabled = true },
        --
        --       referencesCodeLens = { enabled = true, showOnAllFunctions = true },
        --       inlayHints = {
        --         includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all'
        --         includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        --         includeInlayVariableTypeHints = true,
        --         includeInlayFunctionParameterTypeHints = true,
        --         includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        --         includeInlayPropertyDeclarationTypeHints = true,
        --         includeInlayFunctionLikeReturnTypeHints = true,
        --         includeInlayEnumMemberValueHints = true,
        --       },
        --     },
        --     javascript = {
        --       implementationsCodeLens = { enabled = true },
        --       referencesCodeLens = { enabled = true, showOnAllFunctions = true },
        --
        --       inlayHints = {
        --         includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all'
        --         includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        --         includeInlayVariableTypeHints = true,
        --
        --         includeInlayFunctionParameterTypeHints = true,
        --         includeInlayVariableTypeHintsWhenTypeMatchesName = true,
        --         includeInlayPropertyDeclarationTypeHints = true,
        --         includeInlayFunctionLikeReturnTypeHints = true,
        --         includeInlayEnumMemberValueHints = true,
        --       },
        --     },
        --   },
        -- },

        stylelint_lsp = {
          filetypes = {
            "css",
            "scss",
            "less",
            "postcss",
          },
          settings = {
            ---@diagnostic disable-next-line: missing-fields
            stylelintplus = {
              autoFixOnSave = true,
              validateOnSave = true,
              validateOnType = true,
              autoFixOnFormat = true,
            },
          },
        },
      },
    },
  },
}
