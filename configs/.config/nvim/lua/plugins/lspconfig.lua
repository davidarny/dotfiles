return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      ---@diagnostic disable-next-line: missing-fields
      servers = {
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
