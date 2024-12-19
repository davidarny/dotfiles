--- A snazzy bufferline for Neovim.
---
--- See `:help bufferline.nvim` for more information.
--- GitHub: https://github.com/akinsho/bufferline.nvim
return {
  'akinsho/bufferline.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = 'nvim-tree/nvim-web-devicons',
  -- stylua: ignore
  keys = {
    { '<leader>bp', '<cmd>BufferLineTogglePin<CR>',            desc = 'Toggle pin' },
    { '<leader>bP', '<cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete non-pinned buffers' },
    { '<leader>bo', '<cmd>BufferLineCloseOthers<CR>',          desc = 'Delete other buffers' },
    { '<leader>br', '<cmd>BufferLineCloseRight<CR>',           desc = 'Delete buffers to the right' },
    { '<leader>bl', '<cmd>BufferLineCloseLeft<CR>',            desc = 'Delete buffers to the left' },
    { '<S-h>',      '<cmd>BufferLineCyclePrev<cr>',            desc = 'Prev buffer' },
    { '<S-l>',      '<cmd>BufferLineCycleNext<cr>',            desc = 'Next buffer' },
    { '[b',         '<cmd>BufferLineCyclePrev<cr>',            desc = 'Prev buffer' },
    { ']b',         '<cmd>BufferLineCycleNext<cr>',            desc = 'Next buffer' },
    { '[B',         '<cmd>BufferLineMovePrev<cr>',             desc = 'Move buffer prev' },
    { ']B',         '<cmd>BufferLineMoveNext<cr>',             desc = 'Move buffer next' },
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
