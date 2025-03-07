return {
  "folke/snacks.nvim",
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
