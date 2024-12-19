--- Highlight other uses of the word under the cursor using
--- either LSP, Tree-sitter, or regex matching.
---
--- See `:help vim-illuminate` for more information.
--- GitHub: https://github.com/RRethy/vim-illuminate
return {
  'RRethy/vim-illuminate',
  event = 'VeryLazy',
  config = function()
    require('illuminate').configure {}
  end,
}
