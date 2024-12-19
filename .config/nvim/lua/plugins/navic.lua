--- Simple winbar/statusline plugin that shows your current code context.
---
--- See `:help nvim-navic` for more information.
--- GitHub: https://github.com/SmiteshP/nvim-navic
return {
  'SmiteshP/nvim-navic',
  event = 'VeryLazy',
  config = function()
    require('nvim-navic').setup {}
  end,
}
