--- Highlight colors in Neovim.
---
--- See `:help nvim-highlight-colors` for more information.
--- GitHub: https://github.com/brenoprata10/nvim-highlight-colors
return {
  'brenoprata10/nvim-highlight-colors',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    require('nvim-highlight-colors').setup {}
  end,
}
