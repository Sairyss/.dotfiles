-- Inside herdr, also listen on a socket whose name is built from the pane id, so that other tools can find the nvim
-- of a pane without searching processes. This file is the one place that defines the convention; its users
-- (herdr-run --edit of the herdr-task-runner plugin, the herdr-broot-sidebar plugin) only read the socket and fall
-- back to doing nothing when there is none:
--   $XDG_RUNTIME_DIR (else $TMPDIR, else /tmp; an empty variable counts as unset)
--   /herdr-nvim-<pane id, every character that is not a letter or digit replaced by _>.sock
-- An nvim started inside another nvim's terminal inherits the pane id: it finds the socket alive and leaves it.
local function env(name)
  local v = vim.env[name]
  return v ~= nil and v ~= "" and v or nil
end

local pane = vim.env.HERDR_PANE_ID
if pane and pane ~= "" then
  local dir = env("XDG_RUNTIME_DIR") or env("TMPDIR") or "/tmp"
  local path = dir .. "/herdr-nvim-" .. (pane:gsub("[^%w]", "_")) .. ".sock"
  local alive = false
  if vim.uv.fs_stat(path) then
    -- a crashed nvim leaves its socket behind: only a live one is respected
    local ok, chan = pcall(vim.fn.sockconnect, "pipe", path, { rpc = false })
    if ok and chan > 0 then
      vim.fn.chanclose(chan)
      alive = true
    else
      vim.uv.fs_unlink(path)
    end
  end
  if not alive then
    pcall(vim.fn.serverstart, path)
  end
end
