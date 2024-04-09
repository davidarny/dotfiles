local VIEW_WIDTH_FIXED = 35
local view_width_max = -1 -- fixed to start

-- toggle the width and redraw
local function toggle_width_adaptive()
  if view_width_max == -1 then
    view_width_max = VIEW_WIDTH_FIXED
  else
    view_width_max = -1
  end

  require("nvim-tree.api").tree.reload()
end

-- get current view width
local function get_view_width_max()
  return view_width_max
end

return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      disable_netrw = true,
      respect_buf_cwd = true,
      sync_root_with_cwd = true,

      update_focused_file = {
        enable = true,
        update_root = true,
      },

      renderer = {
        icons = {
          git_placement = "after",
        },
      },

      view = {
        side = "right",
        width = {
          min = 35,
          max = get_view_width_max,
        },
      },

      live_filter = {
        always_show_folders = false, -- Turn into false from true by default
      },

      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, noremap = true, silent = true, nowait = true }
        end

        api.config.mappings.default_on_attach(bufnr)

        vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts("Toggle"))
        vim.keymap.set("n", "<leader>ea", toggle_width_adaptive, opts("Toggle Width"))
      end,
    })
  end,
}
