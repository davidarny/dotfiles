--- Faster LuaLS setup for Neovim.
---
--- GitHub: https://github.com/folke/lazydev.nvim
return {

  'folke/lazydev.nvim',
  ft = 'lua',
  cmd = 'LazyDev',
  opts = {
    library = {
      { path = 'snacks.nvim', words = { 'Snacks' } },
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  },
}
