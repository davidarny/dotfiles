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
  },
}
