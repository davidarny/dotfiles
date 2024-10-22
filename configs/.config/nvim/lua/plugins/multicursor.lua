return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  event = 'VeryLazy',
  config = function()
    local mc = require 'multicursor-nvim'
    mc.setup()

    local map = vim.keymap.set

    -- Add or skip cursor above/below the main cursor.
    -- map({ 'n', 'v' }, '<up>', function() mc.lineAddCursor(-1) end)
    -- map({ 'n', 'v' }, '<down>', function() mc.lineAddCursor(1) end)
    -- map({ 'n', 'v' }, '<leader><up>', function() mc.lineSkipCursor(-1) end)
    -- map({ 'n', 'v' }, '<leader><down>', function() mc.lineSkipCursor(1) end)

    -- Add or skip adding a new cursor by matching word/selection
    -- stylua: ignore start
    map({ 'n', 'v' }, '<leader>mn', function() mc.matchAddCursor(1) end, { desc = 'Add cursor above' })
    map({ 'n', 'v' }, '<leader>ms', function() mc.matchSkipCursor(1) end, { desc = 'Skip cursor above' })
    map({ 'n', 'v' }, '<leader>mN', function() mc.matchAddCursor(-1) end, { desc = 'Add cursor below' })
    map({ 'n', 'v' }, '<leader>mS', function() mc.matchSkipCursor(-1) end, { desc = 'Skip cursor below' })

    -- Add all matches in the document
    map({ 'n', 'v' }, '<leader>ma', mc.matchAllAddCursors, { desc = 'Select all matches' })

    -- Align cursor columns.
    map('n', '<leader>ml', mc.alignCursors, { desc = 'Align cursors' })

    -- You can also add cursors with any motion you prefer:
    -- set("n", "<right>", function()
    --     mc.addCursor("w")
    -- end)
    -- set("n", "<leader><right>", function()
    --     mc.skipCursor("w")
    -- end)

    -- Rotate the main cursor.
    -- map({ 'n', 'v' }, '<left>', mc.nextCursor)
    -- map({ 'n', 'v' }, '<right>', mc.prevCursor)

    -- Delete the main cursor.
    -- map({ 'n', 'v' }, '<leader>x', mc.deleteCursor)

    -- Add and remove cursors with control + left click.
    -- map('n', '<c-leftmouse>', mc.handleMouse)

    -- Easy way to add and remove cursors using the main cursor.
    -- map({ 'n', 'v' }, '<c-q>', mc.toggleCursor)

    -- Clone every cursor and disable the originals.
    -- map({ 'n', 'v' }, '<leader><c-q>', mc.duplicateCursors)

    map('n', '<esc>', function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      elseif mc.hasCursors() then
        mc.clearCursors()
      else
        -- Default <esc> handler.
      end
    end)

    -- bring back cursors if you accidentally clear them
    -- map('n', '<leader>gv', mc.restoreCursors)

    -- Split visual selections by regex.
    -- map('v', 'S', mc.splitCursors)

    -- Append/insert for each line of visual selections.
    -- map('v', 'I', mc.insertVisual)
    -- map('v', 'A', mc.appendVisual)

    -- match new cursors within visual selections by regex.
    -- map('v', 'M', mc.matchCursors)

    -- Rotate visual selection contents.
    -- map('v', '<leader>t', function() mc.transposeCursors(1) end)
    -- map('v', '<leader>T', function() mc.transposeCursors(-1) end)

    -- Jumplist support
    -- map({ 'v', 'n' }, '<c-i>', mc.jumpForward)
    -- map({ 'v', 'n' }, '<c-o>', mc.jumpBackward)

    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, 'MultiCursorCursor', { link = 'Cursor' })
    hl(0, 'MultiCursorVisual', { link = 'Visual' })
    hl(0, 'MultiCursorSign', { link = 'SignColumn' })
    hl(0, 'MultiCursorDisabledCursor', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
    -- stylua: ignore end
  end,
}
