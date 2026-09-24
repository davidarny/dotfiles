-- The oxc extra adds oxfmt after prettier for every JS/TS/JSON file, and oxfmt
-- ignores the project's Prettier config (quotes, arrow parens). Run it only in
-- projects that configure oxfmt itself; conform's default also matches
-- vite.config.*, which says nothing about the formatter.
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters = opts.formatters or {}
    opts.formatters.oxfmt = vim.tbl_deep_extend("force", opts.formatters.oxfmt or {}, {
      require_cwd = true,
      cwd = require("conform.util").root_file({ ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }),
    })
  end,
}
