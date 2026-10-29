-- Terminal title: "<file> (<dir> claude:<state>) - Nvim", like nvim's default "<file> (<dir>) - Nvim"; the
-- claude:<state> part is only there while claudecode.nvim's terminal is alive.
-- herdr reads it: herdr-auto-title builds tab names from it (a path-like parenthetical is dropped, so the state
-- doesn't leak into tab names) and the herdr-task-runner plugin (sidebar.py) registers nvim panes from it and takes
-- the state of the claude running inside, which herdr can't see inside an nvim terminal buffer.
-- Keep the format in sync with both.
vim.o.title = true

local dir = ""
local claude = nil -- nil | "idle" | "working" | "blocked"

local function escape(s)
  return (s:gsub("%%", "%%%%"))
end

local function update()
  -- %t is "env" for the claude terminal buffer, which says nothing
  local file = "%{&buftype ==# 'terminal' ? 'terminal' : (expand('%:t') ==# '' ? '[No Name]' : expand('%:t'))}"
  vim.o.titlestring = file .. " (" .. escape(dir) .. (claude and (" claude:" .. claude) or "") .. ") - Nvim"
end

local function set_dir()
  dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  update()
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

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, { callback = set_dir })
vim.uv.new_timer():start(
  1000,
  1000,
  vim.schedule_wrap(function()
    local state = claude_state()
    if state ~= claude then
      claude = state
      update()
    end
  end)
)
set_dir()
