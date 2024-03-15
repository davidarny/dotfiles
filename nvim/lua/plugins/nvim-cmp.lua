return {
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")

      opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      })

      opts.preselect = cmp.PreselectMode.None

      opts.completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      }
    end,
  },
}
