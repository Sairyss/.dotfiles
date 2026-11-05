-- Inside herdr, report the state of the claude running in claudecode.nvim's terminal to herdr, which can't see
-- inside an nvim terminal buffer: the pane is registered as agent `nvim` and claude's state (idle, working,
-- blocked) is its agent state. Nothing here uses the terminal title.
-- The source and the token (kind=nvim, which the agents panel sorts by) are those of the herdr-task-runner plugin
-- (settings herdr.source and kinds.* in its config.default.toml); sidebar.py leaves a pane with that token alone.
-- herdr is $HERDR_BIN_PATH, else herdr from PATH. Outside herdr nothing happens.
local pane = vim.env.HERDR_PANE_ID
if not pane or pane == "" then
  return
end

local herdr = (vim.env.HERDR_BIN_PATH and vim.env.HERDR_BIN_PATH ~= "") and vim.env.HERDR_BIN_PATH or "herdr"
local source, agent = "agent-sort", "nvim"
local last = nil -- nil (not registered) | "idle" | "working" | "blocked"

local function call(...)
  -- a missing herdr binary is not an error worth showing
  local ok, job = pcall(vim.system, { herdr, ... })
  if ok and vim.v.exiting ~= vim.NIL then
    job:wait(1000) -- nvim is quitting: let the call finish
  end
end

-- seq must be above any earlier report of the source, from any process: wall-clock nanoseconds like sidebar.py
local function now()
  local s, us = vim.uv.gettimeofday()
  return string.format("%d%06d000", s, us)
end

local function report(state)
  call("pane", "report-agent", pane, "--source", source, "--agent", agent, "--state", state, "--seq", now())
  if last == nil then
    call("pane", "report-metadata", pane, "--source", source, "--agent", agent, "--token", "kind=nvim")
  end
  last = state
end

local function release()
  if last == nil then
    return
  end
  call("pane", "release-agent", pane, "--source", source, "--agent", agent, "--seq", now())
  call("pane", "report-metadata", pane, "--source", source, "--clear-token", "kind")
  last = nil
end

-- state of the claude terminal: its terminal title is "✳ <topic>" when idle (or plain text before the first
-- prompt) and its leading glyph animates (◐◑, braille, ...) while working; permission prompts are matched on
-- the visible screen text
local function claude_state()
  local ok, term = pcall(require, "claudecode.terminal")
  local buf = ok and term.get_active_terminal_bufnr and term.get_active_terminal_bufnr()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  local chan = vim.bo[buf].channel
  if not chan or chan == 0 or vim.fn.jobwait({ chan }, 0)[1] ~= -1 then
    return nil
  end
  local c = vim.fn.char2nr(vim.fn.strcharpart(vim.b[buf].term_title or "", 0, 1))
  if c > 0x2000 and c ~= 0x2733 then
    return "working"
  end
  local count = vim.api.nvim_buf_line_count(buf)
  local tail = table.concat(vim.api.nvim_buf_get_lines(buf, math.max(0, count - vim.o.lines), -1, false), "\n")
  for _, needle in ipairs({ "Do you want to", "Would you like to", "Enter to confirm" }) do
    if tail:find(needle, 1, true) then
      return "blocked"
    end
  end
  return "idle"
end

-- Registered only while claude's terminal is alive, so a plain nvim shows as a normal pane.
local timer = vim.uv.new_timer()
timer:start(
  1000,
  1000,
  vim.schedule_wrap(function()
    local state = claude_state()
    if state == nil then
      release()
    elseif state ~= last then
      report(state)
    end
  end)
)

vim.api.nvim_create_autocmd("VimLeavePre", { callback = release })
