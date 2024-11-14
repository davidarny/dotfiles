return {
  'mbbill/undotree',
  event = 'VeryLazy',
  config = function()
    vim.keymap.set('n', '<leader>cu', vim.cmd.UndotreeToggle, { desc = 'Toggle Undo Tree' })
  end,
}
