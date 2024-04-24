return {
  "chrishrb/gx.nvim",
  opts = {
    config = true,
    submodules = false,
  },
  init = function()
    vim.g.netrw_nogx = 1 -- disable netrw gx
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
}
