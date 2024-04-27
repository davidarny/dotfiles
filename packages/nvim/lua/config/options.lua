-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt

opt.list = false -- make the > and other symbol to be hidden when the object is commented.
opt.scrolloff = 10 -- minimal number of screen lines to keep above and below the cursor.
opt.sidescrolloff = 10 -- minimal number of screen lines to keep left and right of the cursor.
opt.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
opt.swapfile = false -- creates a swapfile disable to avoid the annoying prompt
opt.hlsearch = true -- highlight all matches on previous search pattern
opt.relativenumber = false
opt.spelllang = { "en", "ru" }
