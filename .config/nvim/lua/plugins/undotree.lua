--- A plugin for visualizing and navigating undo history.
---
--- See `:help undotree.vim` for more information.
--- GitHub: https://github.com/mbbill/undotree
return {
  'mbbill/undotree',
  event = 'VeryLazy',
  config = function()
    vim.keymap.set('n', '<leader>cu', vim.cmd.UndotreeToggle, { desc = 'Toggle Undo Tree' })
  end,
}
