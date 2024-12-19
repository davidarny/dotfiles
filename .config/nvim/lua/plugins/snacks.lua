--- A collection of small QoL plugins for Neovim.
---
--- See `:help snacks.nvim` for more information.
--- GitHub: https://github.com/folke/snacks.nvim
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    notify = { enabled = true },
    notifier = { enabled = true },
    gitbrowse = { enabled = true },
    scope = { enabled = true },
    rename = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    words = { enabled = true },
    dashboard = { enabled = true },
    styles = { enabled = true },
  },
  keys = {
    -- Buffer Management
    {
      '<leader>bd',
      function()
        Snacks.bufdelete()
      end,
      desc = 'Delete buffer',
    },
    {
      '<leader>ba',
      function()
        Snacks.bufdelete.all()
        require('oil').open()
      end,
      desc = 'Delete all buffers',
    },

    -- Terminal
    {
      '<c-/>',
      function()
        Snacks.terminal()
      end,
      desc = 'Toggle Terminal',
    },
    {
      '<c-_>',
      function()
        Snacks.terminal()
      end,
      desc = 'which_key_ignore',
    },

    -- Rename
    {
      '<leader>cR',
      function()
        Snacks.rename.rename_file()
      end,
      desc = 'Rename File',
    },
  },
}
