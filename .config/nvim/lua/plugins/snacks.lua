return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>sg", false },
  },
  opts = {
    explorer = {
      replace_netrw = true,
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = { layout = { position = "right" } },
        },
      },
    },
  },
}
