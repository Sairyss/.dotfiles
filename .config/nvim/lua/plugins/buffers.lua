-- integrate grapple.nvim with zellij status bar (zjstatus)
local function update_zellij_status_grapple_buffers()
  local grapple = require("grapple")
  local tab_id = vim.api.nvim_get_current_tabpage()
  local root = vim.loop.cwd()
  local id = string.format("tab:%s:%d", root, tab_id)
  local tags = grapple.tags({ id })
  if tags == nil or #tags == 0 then
    vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_tagged_buffers::'")
    return
  end

  -- Truncate to max 4 tags, otherwise zellij statusline overflows
  if #tags > 4 then
    local truncated = {}
    for i = 1, 4 do
      table.insert(truncated, tags[i])
    end
    tags = truncated
  end

  local current_buf_path = vim.api.nvim_buf_get_name(0)
  local message = "#[bg=$surface0,fg=$blue] | "
  for idx, tag in ipairs(tags) do
    local buf_name = tag.path:match("^.+/(.+)$") or tag.path
    buf_name = buf_name and #buf_name > 28 and buf_name:sub(1, 25) .. "..." or buf_name
    local fg_color = tag.path == current_buf_path and "sky" or "overlay2"
    message = message
      .. "#[bg=$surface0,fg=$darkblue]"
      .. "#[bg=$darkblue,fg=$"
      .. fg_color
      .. ",bold]"
      .. "󰐃 "
      .. idx
      .. " "
      .. "#[bg=#282A3A,fg=$"
      .. fg_color
      .. ",bold] "
      .. (buf_name ~= "" and buf_name or ("Buffer #" .. idx))
      -- .. "#[bg=$surface0]"
      -- .. " "
      .. "#[bg=$surface0,fg=#282A3A] "
  end
  vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_tagged_buffers::" .. message .. "'")
end

return {
  {
    "cbochs/grapple.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", lazy = true },
    },
    lazy = false,
    opts = {
      -- scope = "tab_scope",
      icons = true,
      quick_select = "123456789",
      prune = "14d",
      style = "basename",
      scopes = {},
    },
    config = function(_, opts)
      require("telescope").load_extension("grapple")
      local grapple = require("grapple")
      grapple.setup(opts)

      local base_tab_id = string.format("tab:%s:%d", vim.loop.cwd(), 1)
      grapple.define_scope({
        name = base_tab_id,
        desc = "Tab-based scope",
        fallback = "cwd",
        cache = {
          event = { "TabNew" },
          debounce = 200, -- ms
        },
        resolver = function()
          return base_tab_id, vim.loop.cwd()
        end,
      })
      grapple.use_scope(base_tab_id, { notify = false })

      vim.api.nvim_create_autocmd({ "TabNew" }, {
        callback = function()
          local tab_id = vim.api.nvim_get_current_tabpage()
          local root = vim.loop.cwd()
          local id = string.format("tab:%s:%d", root, tab_id)
          grapple.define_scope({
            name = id,
            desc = "Tab-based scope",
            fallback = "cwd",
            cache = {
              event = { "TabNew" },
              debounce = 200, -- ms
            },
            resolver = function()
              return id, root
            end,
          })
        end,
      })

      vim.api.nvim_create_autocmd({ "TabEnter" }, {
        callback = function()
          local tab_id = vim.api.nvim_get_current_tabpage()
          local root = vim.loop.cwd()
          local id = string.format("tab:%s:%d", root, tab_id)
          grapple.use_scope(id, { notify = false })
        end,
      })

      vim.api.nvim_create_autocmd({ "TabClosed" }, {
        callback = function()
          local tab_id = vim.fn.expand("<afile>")
          local root = vim.loop.cwd()
          local id = string.format("tab:%s:%d", root, tab_id)
          grapple.reset({ id = id, notify = false })
          vim.wait(100)
          grapple.delete_scope(id)
        end,
      })

      -- vim.api.nvim_create_autocmd({ "VimLeave" }, {
      --   callback = function()
      --     grapple.prune()
      --   end,
      -- })

      -- integrate with zjstatus
      vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave", "TabEnter", "FocusGained" }, {
        callback = function()
          vim.defer_fn(update_zellij_status_grapple_buffers, 0)
        end,
      })
      vim.api.nvim_create_autocmd({ "VimLeave" }, {
        callback = function()
          vim.fn.system("zellij pipe 'zjstatus::pipe::pipe_neovim_tagged_buffers::'")
        end,
      })
    end,
    keys = {
      { "<BS>", "<cmd>Grapple toggle_tags<cr>", desc = "Grapple menu (Tags)" },
      { "<CR><space>", "<cmd>Grapple toggle_tags<cr>", desc = "Grapple menu (Tags)" },
      { "<CR><CR>", "<cmd>Telescope grapple tags<cr>", desc = "Grapple menu (Telescope)" },
      {
        "<CR>m",
        function()
          require("grapple").toggle()
          update_zellij_status_grapple_buffers()
        end,
        desc = "Toggle tag",
      },
      {
        -- Switch to tags of the current git branch. Useful when working on a feature
        "<leader>gt",
        function()
          require("grapple").use_scope("git_branch")
          vim.defer_fn(update_zellij_status_grapple_buffers, 0)
        end,
        desc = "Git Tags for Branch (Grapple)",
      },
      -- switch to a specific tab with a hotkey
      {
        "<leader>1",
        mode = { "n" },
        ":Grapple select index=1<cr>",
        desc = "Grapple 1",
        silent = true,
      },
      {
        "<leader>2",
        mode = { "n" },
        ":Grapple select index=2<cr>",
        desc = "Grapple 2",
        silent = true,
      },
      {
        "<leader>3",
        mode = { "n" },
        ":Grapple select index=3<cr>",
        desc = "Grapple 3",
        silent = true,
      },
      {
        "<leader>4",
        mode = { "n" },
        ":Grapple select index=4<cr>",
        desc = "Grapple 4",
        silent = true,
      },
      {
        "<leader>5",
        mode = { "n" },
        ":Grapple select index=5<cr>",
        desc = "Grapple 5",
        silent = true,
      },
      { "L", "<cmd>Grapple cycle_tags next<cr>", desc = "Go to next tag" },
      { "H", "<cmd>Grapple cycle_tags prev<cr>", desc = "Go to previous tag" },
    },
  },
}
