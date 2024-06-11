return {
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local cmp = require("cmp")

      table.insert(opts.sources, { name = "supermaven" })

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-y>"] = cmp.mapping(
          cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
          }),
          { "i", "c" }
        ),
      })
    end,

    -- opts = function(_, opts)
    --   local cmp = require("cmp")
    --
    --   opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
    --     ["<cr>"] = cmp.mapping.confirm({ select = false }),
    --   })
    --
    --   table.insert(opts.sources, { name = "supermaven" })
    --
    --   opts.preselect = cmp.preselectmode.none
    --   opts.completion = { completeopt = "menu,menuone,noinsert,noselect" }
    -- end,

    keys = {
      { "<Tab>", false, mode = { "i", "s" } },
      { "<S-Tab>", false, mode = { "i", "s" } },
    },
  },
}
