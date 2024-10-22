return {
  'nvim-lualine/lualine.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },

  config = function()
    local lualine = require 'lualine'
    local overseer = require 'overseer'

    local sections = {
      lualine_a = { 'mode' },
      lualine_b = { { 'branch', icon = '' } },
      lualine_c = {
        {
          'filename',
          path = 0,
          file_status = false,

          fmt = function(name)
            ---@diagnostic disable-next-line: undefined-global
            local icon = MiniIcons.get('file', name)

            -- https://github.com/nvim-lualine/lualine.nvim/issues/1216
            if vim.bo.filetype == 'TelescopePrompt' then
              return ' Searching...'
            elseif vim.bo.filetype == 'qf' then
              return '󰁨 Quickfix'
            elseif vim.bo.filetype == 'oil' then
              return '󱏒 Oil'
            elseif name == '[No Name]' or name == '' then
              return '[No Name]'
            elseif icon ~= nil then
              return icon .. ' ' .. name
            end

            return '󰡯 ' .. name
          end,
        },
        {
          'diagnostics',

          -- Table of diagnostic sources, available sources are:
          --   'nvim_lsp', 'nvim_diagnostic', 'nvim_workspace_diagnostic', 'coc', 'ale', 'vim_lsp'.
          -- or a function that returns a table as such:
          --   { error=error_cnt, warn=warn_cnt, info=info_cnt, hint=hint_cnt }
          sources = { 'nvim_diagnostic', 'nvim_lsp', 'nvim_workspace_diagnostic' },

          -- Displays diagnostics for the defined severity types
          sections = { 'error', 'warn', 'info', 'hint' },

          diagnostics_color = {
            -- Same values as the general color option can be used here.
            error = 'DiagnosticError', -- Changes diagnostics' error color.
            warn = 'DiagnosticWarn', -- Changes diagnostics' warn color.
            info = 'DiagnosticInfo', -- Changes diagnostics' info color.
            hint = 'DiagnosticHint', -- Changes diagnostics' hint color.
          },
          symbols = { error = ' ', warn = ' ', info = ' ', hint = '󰮥 ' },
          colored = true, -- Displays diagnostics status in color if set to true.
          update_in_insert = true, -- Update diagnostics in insert mode.
          always_visible = false, -- Show diagnostics even if there are none.
        },
      },
      lualine_x = {
        {
          'overseer',
          colored = true, -- Color the task icons and counts
          symbols = {
            [overseer.STATUS.FAILURE] = ':',
            [overseer.STATUS.CANCELED] = '󰜺:',
            [overseer.STATUS.SUCCESS] = ':',
            [overseer.STATUS.RUNNING] = ':',
          },
        },
        'encoding',
        'fileformat',
        'filetype',
      },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    }

    lualine.setup {
      options = {
        theme = 'auto',
        globalstatus = vim.o.laststatus == 3,
      },
      -- winbar = winbar,
      sections = sections,
      inactive_sections = sections,
    }
  end,
}
