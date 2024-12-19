-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local disabled_filetypes = { 'oil' }

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('kickstart-format-on-save', { clear = true }),
  callback = function()
    -- Check if not in disabled filetypes
    if not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) then
      -- Safely check for formatters
      pcall(function()
        -- Get list of available formatters
        local clients = vim.lsp.get_active_clients { bufnr = 0 }

        -- Check if any client has formatting capability
        for _, client in ipairs(clients) do
          if client.supports_method 'textDocument/formatting' then
            vim.lsp.buf.format {
              async = false,
              filter = function(c)
                return c.name == client.name
              end,
            }
            break
          end
        end
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("LspProgress", {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
    vim.notify(vim.lsp.status(), "info", {
      id = "lsp_progress",
      title = "LSP Progress",
      opts = function(notif)
        notif.icon = ev.data.params.value.kind == "end" and " "
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})
