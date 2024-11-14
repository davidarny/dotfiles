---@type LazySpec
return {
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
  {
    'mikavilpas/yazi.nvim',
    event = 'VeryLazy',
    keys = {
      -- 👇 in this section, choose your own keymappings!
      {
        '-',
        '<cmd>Yazi<cr>',
        mode = { 'n', 'x' },
        desc = 'Open yazi at the current file',
      },
      {
        -- Open in the current working directory
        '<leader>-',
        '<cmd>Yazi cwd<cr>',
        mode = { 'n', 'x' },
        desc = 'Open yazi in working directory',
      },
    },
    ---@type YaziConfig
    opts = {
      open_multiple_tabs = true,
      open_for_directories = true,

      keymaps = {
        show_help = '~',
      },
    },
  },
}
