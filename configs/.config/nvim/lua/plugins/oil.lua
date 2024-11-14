return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup {
        delete_to_trash = true,
        view_options = { show_hidden = true },
        win_options = { signcolumn = 'yes:2' },
        use_default_keymaps = false,
        keymaps = {
          ['g?'] = 'actions.show_help',
          ['<CR>'] = 'actions.select',
          ['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
          ['<C-h>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
          ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
          ['<C-p>'] = 'actions.preview',
          ['<C-c>'] = 'actions.close',
          ['<C-l>'] = 'actions.refresh',
          -- ['-'] = 'actions.parent', -- NOTE: handled by yazi
          -- ['_'] = 'actions.open_cwd', -- NOTE: handled by yazi
          -- ['`'] = 'actions.cd',
          -- ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory', mode = 'n' },
          ['gs'] = 'actions.change_sort',
          ['gx'] = 'actions.open_external',
          ['g.'] = 'actions.toggle_hidden',
          ['g\\'] = 'actions.toggle_trash',
        },
      }

      vim.keymap.set('n', '+', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
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
