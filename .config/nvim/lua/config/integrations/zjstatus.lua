local show_tabs_on_zjstatus = true
local show_buffers_on_zjstatus = false

----- zellij status line integration https://github.com/dj95/zjstatus
local function clear_zellij_status_tabs()
  -- Clear zellij status line for tabs
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
  local message = "#[bg=$surface0,fg=$blue] | "
  if #tabpages <= 1 then
    clear_zellij_status_tabs()
    return
  end
  for idx, tab in ipairs(tabpages) do
    local bufs = get_tab_buffers(tab)
    local tab_color = tab == tabnr and "sky" or "overlay2"
    local buf_name = bufs[1] and bufs[1]:match("^%s*(.-)%s*$")
    buf_name = buf_name and #buf_name > 20 and buf_name:sub(1, 17) .. "..." or buf_name
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

if show_tabs_on_zjstatus then
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
      callback = function()
        vim.defer_fn(update_zellij_status_tabs, 0)
      end,
    })
    vim.api.nvim_create_autocmd("VimLeave", {
      callback = clear_zellij_status_tabs,
    })
  else
    vim.opt.showtabline = 1
  end
end

local function clear_zellij_status_buffers()
  vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_buffers::'")
end

local function truncate_file_name(file_name)
  if #file_name <= 25 then
    return file_name
  end
  local name, ext = file_name:match("^(.*)%.([^%.]+)$")
  if name and ext then
    return name:sub(1, 22) .. ".." .. ext
  else
    return file_name:sub(1, 25)
  end
end

local function update_zellij_status_buffers()
  local buffers = vim.api.nvim_list_bufs()
  local ignore_list = { "neo-tree", "filesystem", "filetype-match" }
  local current_buf = vim.api.nvim_get_current_buf()
  local message = "#[bg=$surface0,fg=$blue] | "
  local display_buffers = {}
  local current_index = nil

  local function is_valid_buffer(buf)
    if not (vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, "buflisted")) then
      return false
    end
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
      return false
    end
    local file_name = name:match("([^/\\]+)$") or name
    for _, pattern in ipairs(ignore_list) do
      if file_name:lower():find(pattern:lower(), 1, true) then
        return false
      end
    end
    return true
  end

  local function get_display_name(buf, is_current)
    local name = vim.api.nvim_buf_get_name(buf)
    local file_name = name:match("([^/\\]+)$") or name
    file_name = file_name:match("^%s*(.-)%s*$")
    local color = is_current and "sky" or "overlay2"
    return "#[bg=$surface0,fg=$" .. color .. "] " .. truncate_file_name(file_name) .. " "
  end

  -- Build list of valid buffers
  for _, buf in ipairs(buffers) do
    if is_valid_buffer(buf) then
      table.insert(display_buffers, buf)
      if buf == current_buf then
        current_index = #display_buffers
      end
    end
  end

  local total = #display_buffers
  if total == 0 then
    clear_zellij_status_buffers()
    return
  end

  if total <= 5 or not current_index then
    -- Show up to 5 buffers directly
    for i, buf in ipairs(display_buffers) do
      if i > 5 then
        break
      end
      message = message .. get_display_name(buf, buf == current_buf)
    end
    if total > 5 then
      message = message .. "#[bg=$surface0,fg=$overlay2].." .. (total - 5)
    end
  else
    local visible_buffers = {}

    -- Start with current buffer
    table.insert(visible_buffers, current_buf)

    local left = current_index - 1
    local right = current_index + 1

    -- Always add at least one buffer after current if it exists
    if right <= total then
      table.insert(visible_buffers, display_buffers[right])
      right = right + 1
    end

    -- Then add up to 2 on the left
    while #visible_buffers < 5 and left >= 1 do
      table.insert(visible_buffers, 1, display_buffers[left])
      left = left - 1
    end

    -- Then fill remaining from the right
    while #visible_buffers < 5 and right <= total do
      table.insert(visible_buffers, display_buffers[right])
      right = right + 1
    end

    -- Count hidden buffers
    local left_hidden = left >= 1 and left or 0
    local right_hidden = right <= total and (total - right + 1) or 0

    -- Show left truncation
    if left_hidden > 0 then
      message = message .. "#[bg=$surface0,fg=$overlay2].." .. left_hidden .. " "
    end

    -- Add visible buffer names
    for _, buf in ipairs(visible_buffers) do
      message = message .. get_display_name(buf, buf == current_buf)
    end

    -- Show right truncation
    if right_hidden > 0 then
      message = message .. "#[bg=$surface0,fg=$overlay2].." .. right_hidden
    end
  end

  vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_buffers::" .. message .. "'")
end

if show_buffers_on_zjstatus and has_current_zellij_session() then
  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufDelete",
    "BufLeave",
    "WinEnter",
    "WinLeave",
    "FocusGained",
    "TabEnter",
  }, {
    callback = function()
      vim.defer_fn(update_zellij_status_buffers, 0)
    end,
  })

  vim.api.nvim_create_autocmd({ "VimLeave" }, {
    callback = clear_zellij_status_buffers,
  })
end
