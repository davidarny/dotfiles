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
