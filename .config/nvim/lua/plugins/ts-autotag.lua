return { -- Automatically add closing tags for HTML and JSX
  'windwp/nvim-ts-autotag',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {},
}
