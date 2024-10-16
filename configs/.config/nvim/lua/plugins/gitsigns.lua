return {
  'lewis6991/gitsigns.nvim',
  event = 'VeryLazy',
  opts = {
    current_line_blame = true,
    signs = {
      add = { text = '' },
      change = { text = '' },
      delete = { text = '' },
      topdelete = { text = '' },
      changedelete = { text = '' },
      untracked = { text = '◌' },
    },
    signs_staged = {
      add = { text = '' },
      change = { text = '' },
      delete = { text = '' },
      topdelete = { text = '' },
      changedelete = { text = '' },
      untracked = { text = '◌' },
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
      end

      -- stylua: ignore start
      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev hunk")
      map("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
      map("n", "[H", function() gs.nav_hunk("first") end, "First hunk")
      map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
      map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
      map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
      map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")
      map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")
      map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk inline")
      map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
      map("n", "<leader>ghB", function() gs.blame() end, "Blame buffer")
      map("n", "<leader>ghd", gs.diffthis, "Diff this")
      map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff this ~")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns select hunk")
    end,
  },
}
