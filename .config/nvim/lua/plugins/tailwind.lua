return {
  --- A Neovim plugin to add vscode-style TailwindCSS completion to nvim-cmp.
  ---
  --- See `:help tailwindcss-colorizer-cmp.nvim` for more information.
  --- GitHub: https://github.com/roobert/tailwindcss-colorizer-cmp.nvim
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
  --- Highlights Tailwind CSS class names when @tailwindcss/language-server is connected.
  ---
  --- See `:help tailwindcss-colorizer-cmp.nvim` for more information.
  --- GitHub: https://github.com/themaxmarchuk/tailwindcss-colors.nvim
  {
    'themaxmarchuk/tailwindcss-colors.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- pass config options here (or nothing to use defaults)
      require('tailwindcss-colors').setup()
    end,
  },
}
