--- The official Neovim plugin for Supermaven.
---
--- See `:help supermaven-nvim` for more information.
--- GitHub: https://github.com/supermaven-inc/supermaven-nvim
return {
  {
    'supermaven-inc/supermaven-nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('supermaven-nvim').setup {}
    end,
  },
}
