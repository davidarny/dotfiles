return {
  'akinsho/bufferline.nvim',
  event = 'VeryLazy',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons',
  keys = {
    { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle [p]in' },
    { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete non-[P]inned [b]uffers' },
    { '<leader>bo', '<Cmd>BufferLineCloseOthers<CR>', desc = 'Delete [o]ther [b]uffers' },
    { '<leader>br', '<Cmd>BufferLineCloseRight<CR>', desc = 'Delete [b]uffers to the [r]ight' },
    { '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Delete [b]uffers to the [l]eft' },
    { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
    { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
    { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev [b]uffer' },
    { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next [b]uffer' },
    { '[B', '<cmd>BufferLineMovePrev<cr>', desc = 'Move [B]uffer prev' },
    { ']B', '<cmd>BufferLineMoveNext<cr>', desc = 'Move [B]uffer next' },
  },
  config = function()
    require('bufferline').setup {
      options = {
        diagnostics = 'nvim_lsp',
        diagnostics_indicator = function(_, _, diagnostics_dict, _)
          local function trim(s)
            return s:match '^%s*(.-)%s*$'
          end

          local s = ' '
          for e, n in pairs(diagnostics_dict) do
            local sym = e == 'error' and ' ' or (e == 'warning' and ' ' or ' ')
            s = s .. n .. sym
          end
          return trim(s)
        end,
      },
    }
  end,
}
