--- Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu.
---
--- See `:help noice.nvim` for more information.
--- GitHub: https://github.com/folke/noice.nvim
return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = {
    lsp = {
      override = {
        ['vim.lsp.util.stylize_markdown'] = true,
        ['cmp.entry.get_documentation'] = true,
        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      },
      hover = {
        silent = true,
      },
    },
    presets = {
      bottom_search = false,
      command_palette = true,
      long_message_to_split = false,
      inc_rename = false,
      lsp_doc_border = true,
    },
  },
  keys = {
    { '<leader>sn', '', desc = '+noice' },
    {
      '<S-Enter>',
      function()
        require('noice').redirect(vim.fn.getcmdline())
      end,
      mode = 'c',
      desc = 'Redirect cmdline',
    },
    {
      '<leader>snl',
      function()
        require('noice').cmd 'last'
      end,
      desc = 'Noice last message',
    },
    {
      '<leader>snh',
      function()
        require('noice').cmd 'history'
      end,
      desc = 'Noice history',
    },
    {
      '<leader>sna',
      function()
        require('noice').cmd 'all'
      end,
      desc = 'Noice all',
    },
    {
      '<leader>snd',
      function()
        require('noice').cmd 'dismiss'
      end,
      desc = 'Dismiss all',
    },
    {
      '<leader>snt',
      function()
        require('noice').cmd 'pick'
      end,
      desc = 'Noice picker (Telescope/FzfLua)',
    },
    {
      '<c-f>',
      function()
        if not require('noice.lsp').scroll(4) then
          return '<c-f>'
        end
      end,
      silent = true,
      expr = true,
      desc = 'Scroll forward',
      mode = { 'i', 'n', 's' },
    },
    {
      '<c-b>',
      function()
        if not require('noice.lsp').scroll(-4) then
          return '<c-b>'
        end
      end,
      silent = true,
      expr = true,
      desc = 'Scroll backward',
      mode = { 'i', 'n', 's' },
    },
  },
}
