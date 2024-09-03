return {
  { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "rose-pine-moon" },
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
      require("lualine").setup({ options = { theme = "rose-pine" } })
    end,
  },
}
