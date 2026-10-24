-- vim-herdr-navigation — Neovim side
--
-- Seamless <M-h/j/k/l> navigation between Neovim splits and herdr panes: move
-- between Neovim splits, and at a split edge hand off to herdr so focus crosses
-- into the neighbouring herdr pane. When not inside herdr it falls back to tmux
-- (if any) or plain wincmd, so a tmux setup keeps working.
--
-- Load it so it wins over other <M-h/j/k/l> mappings (e.g. vim-tmux-navigator).
-- The simplest reliable way is to drop it in your config's after/plugin dir:
--   cp editor/nvim.lua ~/.config/nvim/after/plugin/herdr_nav.lua
-- or source it from your config after plugins load:
--   dofile("/path/to/vim-herdr-navigation/editor/nvim.lua")

local function nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  -- At a split edge: cross into the surrounding multiplexer.
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    -- Target this pane explicitly: `--current` resolves to the server's
    -- globally focused pane, which is not necessarily the one we are in.
    local script = vim.fn.expand("~/.dotfiles/.config/herdr/local-plugins/vim-herdr-navigation/navigate.sh")
    if vim.fn.executable(script) == 1 or vim.fn.filereadable(script) == 1 then
      -- navigate.sh also switches tabs at the edge of the tab; NO_FORWARD avoids bouncing back into nvim
      vim.fn.system({ "env", "HERDR_NAV_NO_FORWARD=1", "bash", script, dir })
    else
      vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--pane", vim.env.HERDR_PANE_ID })
    end
  elseif vim.env.TMUX and vim.env.TMUX ~= "" then
    local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
    pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
  end
end

local function map(lhs, wincmd, dir, desc)
  local function go()
    nav(wincmd, dir)
  end
  vim.keymap.set("n", lhs, go, { silent = true, noremap = true, desc = desc })
  -- Terminal buffers (claude, shell): <M-h/l> would otherwise go to the program inside
  vim.keymap.set("t", lhs, go, { silent = true, noremap = true, desc = desc })
  -- neo-tree: buffer-local so it wins over global mappings (e.g. treewalker's <M-h/l>)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    callback = function(ev)
      vim.keymap.set("n", lhs, go, { buffer = ev.buf, silent = true, noremap = true, desc = desc })
    end,
  })
end

map("<M-h>", "h", "left", "Navigate left (vim/herdr)")
map("<M-l>", "l", "right", "Navigate right (vim/herdr)")
