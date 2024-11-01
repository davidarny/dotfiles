local ignore_patterns = {
  '*.git/*',
  '*build/*',
  '*debug/*',
  '*.pdf',
  '*.ico',
  '*.class',
  '*~',
  '~:',
  '*.jar',
  '*.node',
  '*.lock',
  '*.gz',
  '*.zip',
  '*.7z',
  '*.rar',
  '*.lzma',
  '*.bz2',
  '*.rlib',
  '*.rmeta',
  '*.DS_Store',
  '*.cur',
  -- '*.png',
  -- '*.jpeg',
  -- '*.jpg',
  '*.gif',
  '*.bmp',
  '*.avif',
  '*.heif',
  '*.jxl',
  '*.tif',
  '*.tiff',
  -- '*.ttf',
  -- '*.otf',
  -- '*.woff*',
  '*.sfd',
  '*.pcf',
  -- '*.ico',
  -- '*.svg',
  '*.ser',
  '*.wasm',
  '*.pack',
  '*.pyc',
  '*.apk',
  '*.bin',
  '*.dll',
  '*.pdb',
  '*.db',
  '*.so',
  '*.spl',
  '*.min.js',
  '*.min.gzip.js',
  '*.so',
  '*.doc',
  '*.swp',
  '*.bak',
  '*.ctags',
  '*.doc',
  '*.ppt',
  '*.xls',
  '*.pdf',
}

return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function()
    require 'utils.buffer_previewer'
    local image_preview = telescope_image_preview()

    -- Telescope is a fuzzy finder that comes with a lot of different things that
    -- it can fuzzy find! It's more than just a "file finder", it can search
    -- many different aspects of Neovim, your workspace, LSP, and more!
    --
    -- The easiest way to use Telescope, is to start by doing something like:
    --  :Telescope help_tags
    --
    -- After running this command, a window will open up and you're able to
    -- type in the prompt window. You'll see a list of `help_tags` options and
    -- a corresponding preview of the help.
    --
    -- Two important keymaps to use while in Telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- Telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!

    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      -- defaults = {
      --   mappings = {
      --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
      --   },
      -- },
      -- pickers = {}
      defaults = {
        file_previewer = image_preview.file_previewer,
        buffer_previewer_maker = image_preview.buffer_previewer_maker,
      },
      extensions = {
        file_browser = { hijack_netrw = true },
        ['ui-select'] = { require('telescope.themes').get_dropdown() },
        smart_open = { match_algorithm = 'fzf', cwd_only = true },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search help' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search keymaps' })

    vim.keymap.set('n', '<leader>sf', function()
      require('telescope').extensions.smart_open.smart_open {
        ignore_patterns = ignore_patterns,
      }
    end, { desc = 'Search files' })

    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = 'Search select telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search current word' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search by grep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search diagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Search resume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Search recent files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = 'Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live grep in open files',
      }
    end, { desc = 'Search in open files' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sN', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = 'Search neovim files' })
  end,
}
