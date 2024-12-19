--- Automatically add closing tags for HTML and JSX.
---
--- See `:help nvim-ts-autotag` for more information.
--- GitHub: https://github.com/windwp/nvim-ts-autotag
return {
  'windwp/nvim-ts-autotag',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {},
}
