return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      require('toggleterm').setup {
        open_mapping = { '<C-/>', '<C-_>' },
        inset_mappings = true,
        terminal_mappings = true,
      }
    end,
  },
}
