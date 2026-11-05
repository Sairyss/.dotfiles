-- Inside herdr, tell the broot sidebar of this tab (herdr-broot-sidebar plugin) which file is open, so it works
-- like the file tree of an editor: the tree of nvim's directory (its cwd) with the open file selected.
-- broot draws its tree breadth first to fit the pane and cannot expand a directory in place, so a file deep in a
-- big tree may not be on screen and :select does nothing for it. Then the tree zooms in one directory at a time
-- (the root moves down towards the file) until the file is selected: the closest zoom is the file's directory.
-- Whether :select worked is found with the hbs_report verb of ~/.config/broot/verbs.hjson, which makes a symlink
-- to what is selected; without that verb nothing is checked and only the root's tree is tried.
-- The plugin writes <run dir>/panes.json: pane id -> socket name of the broot in that pane's tab. The run dir is
-- memory (tmpfs), so nothing here reaches the disk: $XDG_RUNTIME_DIR/herdr-broot-sidebar, else
-- $TMPDIR (or /tmp)/herdr-broot-sidebar-<uid>, as in the plugin. broot is $BROOT_BIN, else broot from PATH.
-- Nothing happens without the sidebar (no entry for this pane) or outside herdr.
-- The 0.5 s that the selection check waits for broot is a limit: a slower broot leaves the tree where it is.
-- Off unless HERDR_BROOT_SIDEBAR_NVIM_FOLLOW=1 (also read by the plugin, default 0).
local pane = vim.env.HERDR_PANE_ID
if not pane or pane == "" or not ({ ["1"] = 1, ["true"] = 1, yes = 1, on = 1 })[(vim.env.HERDR_BROOT_SIDEBAR_NVIM_FOLLOW or ""):lower()] then
  return
end
-- Without a sidebar in this tab (the plugin leaves tabs with nvim alone by default, see its README) there is no
-- entry for this pane in panes.json, and nothing below does anything.
local function env(name)
  local v = vim.env[name]
  return v ~= nil and v ~= "" and v or nil
end

local state = env("XDG_RUNTIME_DIR") and (env("XDG_RUNTIME_DIR") .. "/herdr-broot-sidebar")
  or ((env("TMPDIR") or "/tmp") .. "/herdr-broot-sidebar-" .. vim.uv.os_get_passwd().uid)
local broot = env("BROOT_BIN") or "broot"
local last_sock, last_root, last_file, last_cwd, timer
local gen = 0 -- a newer file makes the zooming for an older one stop

local function socket()
  local f = io.open(state .. "/panes.json")
  if not f then
    return nil
  end
  local ok, map = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return ok and type(map) == "table" and map[pane] or nil
end

-- cwd, then each directory below it down to the file's own: where the tree can be rooted, shallowest first.
-- nil for a file outside the cwd (the tree does not jump away from the project for it).
local function roots_for(file, cwd)
  local dir = vim.fs.dirname(file)
  if cwd == "/" or not vim.startswith(dir .. "/", cwd .. "/") then
    return nil
  end
  local roots, cur = { cwd }, cwd
  for part in dir:sub(#cwd + 2):gmatch("[^/]+") do
    cur = cur .. "/" .. part
    roots[#roots + 1] = cur
  end
  return roots
end

local function same_file(a, b)
  return (vim.uv.fs_realpath(a) or a) == (vim.uv.fs_realpath(b) or b)
end

-- try roots[i]; when the file is not selected there, try the next one
local function attempt(my_gen, sock, out, file, roots, i)
  if my_gen ~= gen or i > #roots then
    return
  end
  local root = roots[i]
  vim.uv.fs_unlink(out)
  local cmd = ":select " .. file .. ";:hbs_report " .. out
  -- :focus resets what you expanded in the tree, so only when the root really changes
  if sock ~= last_sock or root ~= last_root then
    cmd = ":focus " .. root .. ";" .. cmd
  end
  last_sock, last_root = sock, root

  local tries = 0
  local function poll()
    if my_gen ~= gen then
      return
    end
    local target = vim.uv.fs_readlink(out)
    if target then
      if not same_file(target, file) then
        attempt(my_gen, sock, out, file, roots, i + 1)
      end
    elseif tries < 12 then -- the verb has not run yet (or does not exist: then we stop after about half a second)
      tries = tries + 1
      vim.defer_fn(poll, 40)
    end
  end
  vim.system({ broot, "--send", sock, "-c", cmd }, {}, function()
    vim.schedule(poll)
  end)
end

local function send(file)
  local sock = socket()
  local cwd = vim.fn.getcwd()
  local roots = sock and roots_for(file, cwd)
  if not roots then
    return
  end
  -- the same file again (window or focus changes fire these events too): nothing to do, and re-sending would
  -- re-render the tree and undo where you browsed in broot. A new sidebar (after a toggle) has a new socket.
  if sock == last_sock and file == last_file and cwd == last_cwd then
    return
  end
  last_file, last_cwd = file, cwd
  vim.fn.mkdir(state .. "/out", "p", "0700")
  gen = gen + 1
  attempt(gen, sock, state .. "/out/" .. sock .. ".sel", file, roots, 1)
end

local function schedule()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  -- real files only (no terminals, help, plugin windows); ";" separates broot commands, a blank would split
  -- the arguments of the verb
  if
    vim.bo[buf].buftype ~= ""
    or file == ""
    or file:find(";", 1, true)
    or vim.fn.filereadable(file) == 0
    or state:find("%s")
  then
    return
  end
  if timer then
    timer:stop()
  else
    timer = vim.uv.new_timer()
  end
  -- debounce: moving through windows and buffers fires many events
  timer:start(80, 0, vim.schedule_wrap(function() send(file) end))
end

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, {
  group = vim.api.nvim_create_augroup("herdr_broot", { clear = true }),
  callback = schedule,
})
