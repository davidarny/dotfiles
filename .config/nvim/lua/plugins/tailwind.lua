return {
  {
    'roobert/tailwindcss-colorizer-cmp.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    -- optionally, override the default options:
    config = function()
      require('tailwindcss-colorizer-cmp').setup {
        color_square_width = 2,
      }
    end,
  },
  {
    'themaxmarchuk/tailwindcss-colors.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- pass config options here (or nothing to use defaults)
      require('tailwindcss-colors').setup()
    end,
  },
}
