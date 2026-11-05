-- The neo-tree actions behind <leader>e and <leader>B (plugins/plugin_options.lua) and behind herdr's prefix+e and
-- prefix+B: the herdr-broot-sidebar plugin calls them through nvim's socket (plugins/herdr/server.lua) in tabs where nvim
-- has no broot sidebar.
local M = {}

local function root_exec(args)
  args.dir = LazyVim.root()
  require("neo-tree.command").execute(args)
end

function M.toggle()
  root_exec({ toggle = true })
end

-- Focus the tree (opening it if needed); from inside it go back to the previous window, unless `back` is false
-- (then the tree is focused even when it already is).
function M.focus(back)
  if back ~= false and vim.bo.filetype == "neo-tree" then
    vim.cmd("wincmd p")
  else
    root_exec({ action = "focus" })
  end
end

return M
