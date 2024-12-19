--- A collection of small QoL plugins for Neovim.
---
--- See `:help snacks.nvim` for more information.
--- GitHub: https://github.com/folke/snacks.nvim
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    bufdelete = { enabled = true },
  },
  -- stylua: ignore
  keys = {
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
    {
      "<leader>ba",
      function()
        Snacks.bufdelete.all()
        require('oil').open()
      end,
      desc = "Delete all buffers"
    },
  },
}
