--- Highlight chunks of code in Neovim.
---
--- See `:help hlchunk.nvim` for more information.
--- GitHub: https://github.com/shellRaining/hlchunk.nvim
return {
  'shellRaining/hlchunk.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local colors = require('tokyonight.colors').setup()

    require('hlchunk').setup {
      chunk = {
        enable = true,
        priority = 15,
        style = colors.magenta,
        use_treesitter = true,
        textobject = '',
        max_file_size = 1024 * 1024,
        error_sign = true,
        chars = {
          horizontal_line = '─',
          vertical_line = '│',
          left_top = '╭',
          left_bottom = '╰',
          right_arrow = '─',
        },
        -- animation related
        duration = 100,
        delay = 100,
      },
    }
  end,
}
