return {
  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    'folke/persistence.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    -- stylua: ignore
    keys = {
      { '<leader>qs', function() require('persistence').load() end,               desc = 'Restore session' },
      { '<leader>qS', function() require('persistence').select() end,             desc = 'Select session' },
      { '<leader>ql', function() require('persistence').load { last = true } end, desc = 'Restore last session' },
      { '<leader>qd', function() require('persistence').stop() end,               desc = "Don't save current session" },
    },
  },

  -- library used by other plugins
  { 'nvim-lua/plenary.nvim', lazy = true },
}
