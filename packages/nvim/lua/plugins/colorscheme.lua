return {
  { "catppuccin/nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
      -- colorscheme = "catppuccin-macchiato",
    },
  },
  {
    "akinsho/bufferline.nvim",
    event = "ColorScheme",
    config = function()
      local highlights = require("rose-pine.plugins.bufferline")
      require("bufferline").setup({ highlights = highlights })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "ColorScheme",
    config = function()
      require("lualine").setup({
        options = {
          --- @usage 'rose-pine' | 'rose-pine-alt'
          theme = "rose-pine",
        },
      })
    end,
  },
}
