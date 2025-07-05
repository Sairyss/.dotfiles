-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

----- zellij status line integration https://github.com/dj95/zjstatus
local function clear_zellij_status_tabs()
  -- Clear the zellij status line for tabs
  vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_tabs::'")
end

local function get_tab_buffers(tabnr)
  -- ignore buffers that contain these patterns
  local ignore_list = { "nvimtree", "help", "neo-tree" }

  local wins = vim.api.nvim_tabpage_list_wins(tabnr)
  local bufs = {}
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local ignore = false
    for _, pattern in ipairs(ignore_list) do
      if string.find(buf_name:lower(), pattern, 1, true) then
        ignore = true
        break
      end
    end
    if not ignore then
      local file_name = buf_name:match("([^/\\]+)$") or buf_name
      table.insert(bufs, file_name)
    end
  end
  return bufs
end

local function update_zellij_status_tabs()
  local tabnr = vim.api.nvim_get_current_tabpage()
  local tabpages = vim.api.nvim_list_tabpages()
  local message = "#[fg=$blue] | "
  if #tabpages <= 1 then
    clear_zellij_status_tabs()
    return
  end
  for idx, tab in ipairs(tabpages) do
    local bufs = get_tab_buffers(tab)
    local tab_color = tab == tabnr and "sky" or "overlay2"
    local buf_name = bufs[1] and bufs[1]:match("^%s*(.-)%s*$") -- trim whitespace
    buf_name = buf_name and #buf_name > 25 and buf_name:sub(1, 25) .. "..." or buf_name
    message = message
      .. "#[bg=$surface0,fg=$"
      .. tab_color
      .. "]█#[bg=$"
      .. tab_color
      .. ",fg=$crust,bold]"
      .. idx
      .. " #[bg=$surface1,fg=$"
      .. tab_color
      .. ",bold] "
      .. (buf_name ~= "" and buf_name or ("Tab #" .. idx))
      .. "#[bg=$surface0,fg=$surface1]█ "
  end
  vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_tabs::" .. message .. "'")
end

-- check if zellij is active. if not we do not load the script
local function has_current_zellij_session()
  local handle = io.popen("zellij list-sessions")
  if not handle then
    return false
  end

  local output = handle:read("*a")
  handle:close()

  return output:match("%(current%)") ~= nil
end

if has_current_zellij_session() then
  vim.opt.showtabline = 0 -- hide tabs
  vim.api.nvim_create_autocmd({
    "TabEnter",
    "TabClosed",
    "BufEnter",
    "BufDelete",
    "TermEnter",
    "TermLeave",
    "WinEnter",
    "WinLeave",
    "FocusGained",
  }, {
    callback = update_zellij_status_tabs,
  })
  vim.api.nvim_create_autocmd("VimLeave", {
    callback = clear_zellij_status_tabs,
  })
else
  vim.opt.showtabline = 1
end
