return {
  --- Find And Replace plugin for neovim.
  ---
  --- See `:help grug-far.nvim` for more information.
  --- GitHub: https://github.com/MagicDuck/grug-far.nvim
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>sp',
        function()
          local grug = require 'grug-far'
          grug.setup {}

          local ext = vim.bo.buftype == '' and vim.fn.expand '%:e'
          grug.open {
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= '' and '*.' .. ext or nil,
            },
          }
        end,
        mode = { 'n', 'v' },
        desc = 'Search and Replace',
      },
    },
  },
  --- A Neovim Plugin for the yazi terminal file manager
  ---
  --- See `:help yazi.nvim` for more information.
  --- GitHub: https://github.com/mikavilpas/yazi.nvim
  {
    'mikavilpas/yazi.nvim',
    event = 'VeryLazy',
    keys = {
      -- 👇 in this section, choose your own keymappings!
      {
        '<leader>zf',
        '<cmd>Yazi<cr>',
        mode = { 'n', 'x' },
        desc = 'Open yazi at the current file',
      },
      {
        -- Open in the current working directory
        '<leader>zc',
        '<cmd>Yazi cwd<cr>',
        mode = { 'n', 'x' },
        desc = 'Open yazi in working directory',
      },
    },
    opts = {
      open_multiple_tabs = true,
      open_for_directories = false,

      keymaps = {
        show_help = '~',
      },
    },
  },
}
