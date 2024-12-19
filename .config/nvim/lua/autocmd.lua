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
