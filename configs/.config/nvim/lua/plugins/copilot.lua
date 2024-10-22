local M = {}

---@param kind string
function M.pick(kind)
  return function()
    local actions = require 'CopilotChat.actions'
    local items = actions[kind .. '_actions']()
    if not items then
      vim.notify('No ' .. kind .. ' found on the current line', vim.log.levels.WARN, { title = 'Copilot Chat' })
      return
    end
    local ok = pcall(require, 'fzf-lua')
    require('CopilotChat.integrations.' .. (ok and 'fzflua' or 'telescope')).pick(items)
  end
end

return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    build = ':Copilot auth',
    config = function()
      require('copilot').setup {
        suggestion = { enabled = false },
        panel = { enabled = false },
        filetypes = {
          markdown = true,
          help = true,
        },
      }
    end,
  },

  { 'AndreM222/copilot-lualine' },

  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'canary',
    event = 'VeryLazy',
    cmd = 'CopilotChat',
    opts = function()
      local user = vim.env.USER or 'User'
      user = user:sub(1, 1):upper() .. user:sub(2)
      return {
        auto_insert_mode = true,
        show_help = true,
        question_header = '  ' .. user .. ' ',
        answer_header = '  Copilot ',
        window = {
          width = 0.4,
        },
        selection = function(source)
          local select = require 'CopilotChat.select'
          return select.visual(source) or select.buffer(source)
        end,
      }
    end,
    keys = {
      {
        '<c-s>',
        '<CR>',
        ft = 'copilot-chat',
        desc = 'Submit prompt',
        remap = true,
      },
      {
        '<leader>a',
        '',
        desc = '+ai',
        mode = { 'n', 'v' },
      },
      -- Show help actions with telescope
      {
        '<leader>ad',
        M.pick 'help',
        desc = 'Diagnostic help (CopilotChat)',
        mode = { 'n', 'v' },
      },
      -- Show prompts actions with telescope
      {
        '<leader>ap',
        M.pick 'prompt',
        desc = 'Prompt actions (CopilotChat)',
        mode = { 'n', 'v' },
      },
      {
        '<leader>aa',
        function()
          return require('CopilotChat').toggle()
        end,
        desc = 'Toggle (CopilotChat)',
        mode = { 'n', 'v' },
      },
      {
        '<leader>ax',
        function()
          return require('CopilotChat').reset()
        end,
        desc = 'Clear (CopilotChat)',
        mode = { 'n', 'v' },
      },
      {
        '<leader>aq',
        function()
          local input = vim.fn.input 'Quick chat: '
          if input ~= '' then
            require('CopilotChat').ask(input)
          end
        end,
        desc = 'Quick chat (CopilotChat)',
        mode = { 'n', 'v' },
      },
    },
    config = function(_, opts)
      local chat = require 'CopilotChat'
      require('CopilotChat.integrations.cmp').setup()

      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = 'copilot-chat',
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
        end,
      })

      chat.setup(opts)
    end,
  },
}
