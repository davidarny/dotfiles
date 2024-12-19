--- Quickstart configs for Nvim LSP.
---
--- See `:help nvim-lspconfig` for more information.
--- GitHub: https://github.com/neovim/nvim-lspconfig
return {

  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
    { 'j-hui/fidget.nvim', opts = {} },
    { 'saghen/blink.cmp' },
  },
  config = function()
    ---@section LSP Capabilities
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    ---@section LSP Keymaps
    local function setup_lsp_keymaps(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Navigation
      map('gd', require('telescope.builtin').lsp_definitions, 'Goto definition')
      map('gr', require('telescope.builtin').lsp_references, 'Goto references')
      map('gr', require('telescope.builtin').lsp_references, 'Goto references')

      -- Jump to the implementation of the word under your cursor.
      --  Useful when your language has ways of declaring types without an actual implementation.
      map('gr', require('telescope.builtin').lsp_references, 'Goto references')

      -- Jump to the implementation of the word under your cursor.
      --  Useful when your language has ways of declaring types without an actual implementation.
      map('gI', require('telescope.builtin').lsp_implementations, 'Goto implementation')
      map('gD', vim.lsp.buf.declaration, 'Goto declaration')
      map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type definition')

      -- Workspace
      map('<leader>ds', require('telescope.builtin').lsp_document_symbols, 'Document symbols')
      map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace symbols')

      -- Actions
      map('<leader>cr', vim.lsp.buf.rename, 'Rename')
      map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })

      -- Source actions
      local action = setmetatable({}, {
        __index = function(_, action)
          return function()
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { action },
                diagnostics = {},
              },
            }
          end
        end,
      })

      map('<leader>cA', action.source, 'Source action', { 'n', 'x' })
    end

    ---@section LSP Highlights
    local function setup_lsp_highlights(event, client)
      if not client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        return
      end

      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })

      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(sub_event)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = sub_event.buf }
        end,
      })
    end

    ---@section LSP Inlay Hints
    local function setup_inlay_hints(event, client)
      if not client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        return
      end

      vim.keymap.set('n', '<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, { buffer = event.buf, desc = 'LSP: Toggle inlay hints' })
    end

    ---@section LSP Attach
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client then
          return
        end

        setup_lsp_keymaps(event)
        setup_lsp_highlights(event, client)
        setup_inlay_hints(event, client)
      end,
    })

    ---@section LSP Servers
    local servers = {
      ---@section TypeScript/JavaScript
      vtsls = {
        settings = {
          typescript = { format = { enable = false } },
          javascript = { format = { enable = false } },
        },
      },
      eslint = {
        settings = {
          workingDirectoriy = { mode = 'auto' },
        },
      },

      ---@section CSS/SCSS/Styling
      cssls = {},
      css_variables = {},
      cssmodules_ls = {},
      somesass_ls = {},
      tailwindcss = {},
      stylelint_lsp = {
        filetypes = { 'css', 'scss', 'postcss' },
        settings = {
          stylelintplus = {
            autoFixOnSave = true,
            validateOnSave = true,
            validateOnType = true,
            autoFixOnFormat = true,
          },
        },
      },

      ---@section Formatting
      prettier = {},
      stylua = {},
      shfmt = {},

      ---@section Documentation
      markdownlint = {},

      ---@section Shell
      bashls = {},

      ---@section Nix
      ['nil_ls'] = {
        settings = {
          ['nil'] = {
            formatting = {
              command = { 'nixfmt' },
            },
          },
        },
      },

      ---@section Lua
      lua_ls = {},
    }

    ---@section LSP Setup
    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }
  end,
}
