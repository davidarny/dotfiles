--- A telescope.nvim extension designed to provide the best
--- possible suggestions for quickly opening files in Neovim.
--- smart-open will improve its suggestions over time, adapting to your usage.
---
--- See `:help smart-open.nvim` for more information.
--- GitHub: https://github.com/danielfalk/smart-open.nvim
return {
  'danielfalk/smart-open.nvim',
  branch = '0.2.x',
  config = function()
    require('telescope').load_extension 'smart_open'
  end,
  dependencies = {
    'kkharji/sqlite.lua',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
}
