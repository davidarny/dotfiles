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
  -- stylua: ignore
  keys = {
    -- Buffer Management
    { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete buffer' },
    { '<leader>ba', function() Snacks.bufdelete.all() end, desc = 'Delete all buffers' },

    -- Terminal
    { '<c-/>', function() Snacks.terminal() end, desc = 'Toggle Terminal' },
    { '<c-_>', function() Snacks.terminal() end, desc = 'which_key_ignore' },

    -- Rename
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File' },

    -- Words
    { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', mode = { 'n', 't' } },
    { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', mode = { 'n', 't' } },

    -- Git Browse
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git Browse', mode = { 'n', 'v' } },
  },
}
