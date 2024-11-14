return { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    icons = {
      -- set icon mappings to true if you have a Nerd Font
      mappings = vim.g.have_nerd_font,
      -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
      -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
      -- stylua: ignore
      keys = vim.g.have_nerd_font and {} or {
        Up              = '<Up> ',
        Down            = '<Down> ',
        Left            = '<Left> ',
        Right           = '<Right> ',
        C               = '<C-…> ',
        M               = '<M-…> ',
        D               = '<D-…> ',
        S               = '<S-…> ',
        CR              = '<CR> ',
        Esc             = '<Esc> ',
        ScrollWheelDown = '<ScrollWheelDown> ',
        ScrollWheelUp   = '<ScrollWheelUp> ',
        NL              = '<NL> ',
        BS              = '<BS> ',
        Space           = '<Space> ',
        Tab             = '<Tab> ',
        F1              = '<F1>',
        F2              = '<F2>',
        F3              = '<F3>',
        F4              = '<F4>',
        F5              = '<F5>',
        F6              = '<F6>',
        F7              = '<F7>',
        F8              = '<F8>',
        F9              = '<F9>',
        F10             = '<F10>',
        F11             = '<F11>',
        F12             = '<F12>',
      },
    },

    -- Document existing key chains
    -- stylua: ignore
    spec = {
      { '<BS>', desc = 'Decrement selection', mode = 'x' },
      { '<C-space>', desc = 'Increment selection', mode = { 'x', 'n' } },
      { '<leader>c', group = 'Code', mode = { 'n', 'x' } },
      { '<leader>d', group = 'Document', icon = '󰈙' },
      { '<leader>r', group = 'Rename' },
      { '<leader>s', group = 'Search' },
      { '<leader>w', group = 'Workspace', icon = "" },
      { '<leader>t', group = 'Toggle' },
      { '<leader>h', group = 'Git hunk', mode = { 'n', 'v' } },
      { '<leader>o', group = 'Tasks', icon = "" },
      { '<leader>m', group = 'Multicursor', mode = { 'n', 'v' }, icon = "󰇀" },
      { '<leader>g', group = 'Git' },
      { '<leader>x', group = 'Diagnostic' },
      { '<leader>b', group = 'Buffer' },
      { '<leader>q', group = 'Session' },
      { '<leader>-', group = "Open yazi in working directory", icon = '󰈙' }
    },
  },
}
