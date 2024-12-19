--- Highlight, list and search todo comments in your projects.
---
--- See `:help todo-comments.nvim` for more information.
--- GitHub: https://github.com/folke/todo-comments.nvim
return {
  'folke/todo-comments.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { signs = false },
}
