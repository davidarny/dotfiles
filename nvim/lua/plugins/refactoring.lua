return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local refactoring = require("refactoring")

      refactoring.setup()

      vim.keymap.set({ "n", "x" }, "<leader>rr", function()
        require("telescope").extensions.refactoring.refactors()
      end, { desc = "Open Refactoring Menu" })

      vim.keymap.set("n", "<leader>rp", function()
        require("refactoring").debug.printf({ below = false })
      end, { desc = "Print Debug Info" })

      vim.keymap.set({ "x", "n" }, "<leader>rv", function()
        require("refactoring").debug.print_var()
      end, { desc = "Print Variable" })

      vim.keymap.set("n", "<leader>rc", function()
        require("refactoring").debug.cleanup({})
      end, { desc = "Cleanup Debug Info" })
    end,
  },
}
