--- Collection of various small independent plugins/modules.
---
--- See `:help mini.nvim` for more information.
--- GitHub: https://github.com/echasnovski/mini.nvim
return {
  'echasnovski/mini.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('mini.align').setup {}
    require('mini.pairs').setup {}

    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup {
      mappings = {
        add = 'gsa', -- Add surrounding in Normal and Visual modes
        delete = 'gsd', -- Delete surrounding
        find = 'gsf', -- Find surrounding (to the right)
        find_left = 'gsF', -- Find surrounding (to the left)
        highlight = 'gsh', -- Highlight surrounding
        replace = 'gsr', -- Replace surrounding
        update_n_lines = 'gsn', -- Update `n_lines`
      },
    }

    require('mini.icons').setup {
      -- stylua: ignore
      file = {
        ['.eslintrc.js']        = { glyph = '󰱺', hl = 'MiniIconsYellow' },
        ['.node-version']       = { glyph = '', hl = 'MiniIconsGreen' },
        ['.prettierrc']         = { glyph = '', hl = 'MiniIconsPurple' },
        ['.yarnrc.yml']         = { glyph = '', hl = 'MiniIconsBlue' },
        ['eslint.config.js']    = { glyph = '󰱺', hl = 'MiniIconsYellow' },
        ['package.json']        = { glyph = '', hl = 'MiniIconsGreen' },
        ['tsconfig.json']       = { glyph = '', hl = 'MiniIconsAzure' },
        ['tsconfig.build.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        ['yarn.lock']           = { glyph = '', hl = 'MiniIconsBlue' },
      },
    }

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    -- local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    -- statusline.setup { use_icons = vim.g.have_nerd_font }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    -- statusline.section_location = function()
    --   return '%2l:%-2v'
    -- end

    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
