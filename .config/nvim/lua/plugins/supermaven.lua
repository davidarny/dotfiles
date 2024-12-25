return {
  'supermaven-inc/supermaven-nvim',
  event = 'InsertEnter',
  cmd = {
    'SupermavenUseFree',
    'SupermavenUsePro',
  },
  opts = {
    keymaps = {
      accept_suggestion = nil, -- handled by nvim-cmp / blink.cmp
    },
    disable_inline_completion = true,
  },
}
