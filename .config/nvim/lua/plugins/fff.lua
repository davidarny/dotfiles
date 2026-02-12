return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    keys = {
      {
        "<leader><space>",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Find Files - fff (Root Dir)",
      },
      {
        "<leader>ff",
        function()
          require("fff").find_in_git_root()
        end,
        desc = "Find Files - fff (Root Dir)",
      },
      {
        "<leader>fF",
        function()
          require("fff").find_files()
        end,
        desc = "Find Files - fff (cwd)",
      },
    },
  },
}
