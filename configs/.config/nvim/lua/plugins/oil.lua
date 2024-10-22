return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup {
        delete_to_trash = true,
        view_options = { show_hidden = true },
        win_options = { signcolumn = 'yes:2' },
      }

      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    end,
  },
  {
    'cosmicbuffalo/oil-git-status.nvim',
    dependencies = { 'stevearc/oil.nvim' },
    config = function()
      require('oil-git-status').setup {
        show_ignored = true,
        symbols = { -- customize the symbols that appear in the git status columns
          index = {
            ['!'] = '◌',
            ['?'] = '',
            ['A'] = '',
            ['C'] = '',
            ['D'] = '',
            ['M'] = '󱇧',
            ['R'] = '➜',
            ['T'] = '❖',
            ['U'] = '',
            [' '] = ' ',
          },
          working_tree = {
            ['!'] = '◌',
            ['?'] = '',
            ['A'] = '',
            ['C'] = '',
            ['D'] = '',
            ['M'] = '󱇧',
            ['R'] = '➜',
            ['T'] = '❖',
            ['U'] = '',
            [' '] = ' ',
          },
        },
      }
    end,
  },
}
