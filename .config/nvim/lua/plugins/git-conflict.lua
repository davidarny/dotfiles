--- A plugin to visualise and resolve merge conflicts in Neovim.
---
--- See `:help git-conflict.nvim` for more information.
--- GitHub: https://github.com/akinsho/git-conflict.nvim
return {
  'akinsho/git-conflict.nvim',
  config = true,
  event = { 'BufReadPre', 'BufNewFile' },
}
