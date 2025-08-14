-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.relativenumber = false
vim.opt.swapfile = false

-- LazyVim related
vim.g.snacks_animate = false
vim.diagnostic.config({ virtual_text = false })

-- Ensures that when exiting NeoVim, Zellij returns to normal mode
vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "silent !zellij action switch-mode normal",
})

----- Performance improvements -----
-- https://github.com/LazyVim/LazyVim/discussions/326

-- disable lsp logs to improve performance
vim.lsp.set_log_level("off")

-- https://vi.stackexchange.com/a/5318/12823
vim.g.matchparen_timeout = 2
vim.g.matchparen_insert_timeout = 2

-- vim.opt.syntax = "off"
-- vim.o.foldenable = false
-- vim.o.spell = false

----- end performance improvements -----
