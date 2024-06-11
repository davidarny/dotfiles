return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "marilari88/twoslash-queries.nvim",
      init = function()
        require("lazyvim.util").lsp.on_attach(function(client, buffer)
          require("twoslash-queries").attach(client, buffer)
        end)
      end,
    },
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
