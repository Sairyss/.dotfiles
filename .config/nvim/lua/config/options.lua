-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.relativenumber = false
vim.opt.swapfile = false

-- LazyVim related
vim.g.snacks_animate = false

-- Ensures that when exiting NeoVim, Zellij returns to normal mode
vim.api.nvim_create_autocmd("VimLeave", {
  pattern = "*",
  command = "silent !zellij action switch-mode normal",
})

-- Over SSH, or without a usable Wayland clipboard (e.g. inside a container), copy via
-- OSC 52 so the text lands in the host's clipboard through the terminal.
-- Paste returns the last yank: most terminals don't allow OSC 52 reads.
-- LazyVim clears 'clipboard' over SSH, so re-enable it to make plain `y` use OSC 52.
local has_wl = vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or not has_wl then
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = { {}, "v" }
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste()
    return last
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
  vim.opt.clipboard = "unnamedplus"
-- Use wl-clipboard on Wayland to avoid xsel BadWindow errors
else
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = { ["+"] = "wl-copy", ["*"] = "wl-copy --primary" },
    paste = { ["+"] = "wl-paste --no-newline", ["*"] = "wl-paste --no-newline --primary" },
    cache_enabled = 0,
  }
end

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

-- terminal title (read by herdr)
require("config.title")
