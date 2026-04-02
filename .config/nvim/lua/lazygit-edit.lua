local M = {}

function M.open(filename, line)
  for _, win in pairs(Snacks.terminal.list()) do
    if win.buf and vim.bo[win.buf].filetype == "snacks_terminal" then
      if (vim.b[win.buf].term_title or ""):match("lazygit") then
        win:close({ buf = true })
        break
      end
    end
  end

  vim.schedule(function()
    if line then
      vim.cmd("edit +" .. line .. " " .. vim.fn.fnameescape(filename))
    else
      vim.cmd("edit " .. vim.fn.fnameescape(filename))
    end
  end)
end

return M
