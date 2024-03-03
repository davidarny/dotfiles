return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")

      opts.mapping["<CR>"] = nil
      opts.mapping["<S-CR>"] = nil
      opts.mapping["<C-CR>"] = nil

      opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
      })

      table.insert(opts.sources, { name = "emoji" })
    end,
  },
}
