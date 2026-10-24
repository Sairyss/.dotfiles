-- Send the path of the neo-tree node under the cursor to the herdr agent (same target
-- resolution and path formatting as herdr-nvim's <leader>ai, which in neo-tree would
-- otherwise cite the tree buffer's line number)
local M = {}

function M.send(state)
  local node = state.tree:get_node()
  if not node or not node.path then
    return
  end
  local path = node.path
  local ok_mod, agents = pcall(require, "herdr-nvim.agents")
  if not ok_mod then
    vim.notify("herdr-nvim: not running inside herdr", vim.log.levels.WARN)
    return
  end
  local dispatch = require("herdr-nvim.dispatch")
  local prompt = require("herdr-nvim.prompt")

  local list, err = agents.list()
  if not list then
    vim.notify("herdr-nvim: " .. err, vim.log.levels.WARN)
    return
  end
  if #list == 0 then
    vim.notify("herdr-nvim: no herdr agent running in this workspace", vim.log.levels.WARN)
    return
  end
  local function deliver(agent)
    local payload = prompt._relpath(path, agent.cwd) .. " "
    local ok, derr = dispatch.send(agent.pane_id, payload, { submit = false })
    if not ok then
      vim.notify("herdr-nvim: " .. derr, vim.log.levels.ERROR)
      return
    end
    vim.notify("herdr-nvim: referenced " .. vim.trim(payload))
  end
  local agent = agents.resolve(list)
  if agent then
    deliver(agent)
  else
    require("herdr-nvim.ui").pick_agent(list, deliver)
  end
end

return M
