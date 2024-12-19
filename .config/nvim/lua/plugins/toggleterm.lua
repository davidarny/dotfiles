--- A neovim lua plugin to help easily manage multiple terminal windows.
---
--- See `:help toggleterm.nvim` for more information.
--- GitHub: https://github.com/akinsho/toggleterm.nvim
return {
  {
    'akinsho/toggleterm.nvim',
    event = 'VeryLazy',
    config = function()
      require('toggleterm').setup {
        open_mapping = { '<C-/>', '<C-_>' },
        inset_mappings = true,
        terminal_mappings = true,
      }
    end,
  },
}
