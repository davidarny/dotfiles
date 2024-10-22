return {
  'lukas-reineke/indent-blankline.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  enabled = false,
  main = 'ibl',
  ---@module "ibl"
  ---@type ibl.config
  opts = {
    indent = {
      char = '│',
      tab_char = '│',
    },
    scope = { show_start = false, show_end = false },
    exclude = {
      filetypes = {
        'help',
        'alpha',
        'Trouble',
        'trouble',
        'lazy',
        'mason',
        'notify',
        'toggleterm',
        'oil',
      },
    },
  },
}
