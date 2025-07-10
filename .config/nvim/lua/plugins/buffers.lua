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
  local current_buf_path = vim.api.nvim_buf_get_name(0)
  local message = "#[bg=$surface0,fg=$blue] | "
  for idx, tag in ipairs(tags) do
    local buf_name = tag.path:match("^.+/(.+)$") or tag.path
    buf_name = buf_name and #buf_name > 30 and buf_name:sub(1, 27) .. "..." or buf_name
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
      prune = "30d",
      style = "basename",
      scopes = {},
    },
    config = function(_, opts)
      local grapple = require("grapple")
      grapple.setup(opts)

      local base_tab_id = string.format("tab:%s:%d", vim.loop.cwd(), 1)
      grapple.define_scope({
        name = base_tab_id,
        desc = "Scope based on tabs",
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
            desc = "Scope based on tabs",
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
      -- { "<BS>", "<cmd>Grapple toggle_tags<cr>", desc = "Toggle tags menu" },
      {
        "<leader>m",
        function()
          require("grapple").toggle()
          update_zellij_status_grapple_buffers()
        end,
        desc = "Toggle tag",
      },
      -- { "H", "<cmd>Grapple cycle_tags next<cr>", desc = "Go to next tag" },
      -- { "L", "<cmd>Grapple cycle_tags prev<cr>", desc = "Go to previous tag" },
    },
  },

  -- {
  --   "otavioschwanck/arrow.nvim",
  --   dependencies = {
  --     { "nvim-tree/nvim-web-devicons" },
  --     -- or if using `mini.icons`
  --     -- { "echasnovski/mini.icons" },
  --   },
  --   opts = {
  --     show_icons = true,
  --     leader_key = "\\", -- Recommended to be a single key
  --     buffer_leader_key = "M", -- Per Buffer Mappings
  --   },
  -- },
  {
    "leath-dub/snipe.nvim",
    keys = {
      -- {
      --   "<leader>,",
      --   function()
      --     require("snipe").open_buffer_menu()
      --   end,
      --   desc = "Snipe buffer menu",
      -- },
      {
        "<leader>bs",
        function()
          require("snipe").open_buffer_menu()
        end,
        desc = "Snipe buffer menu",
      },
      {
        "<BS>",
        mode = { "n" },
        function()
          require("snipe").open_buffer_menu()
        end,
        desc = "Snipe buffer menu",
      },
    },
    config = function()
      require("snipe").setup({
        ui = {
          position = "center",
          open_win_override = {
            border = "rounded",
          },
          text_align = "file-first",
          buffer_format = {
            "icon",
            " ",
            "filename",
            function(buf)
              if vim.fn.isdirectory(vim.api.nvim_buf_get_name(buf.id)) == 1 then
                return " ", "SnipeText"
              end
            end,
          },
        },
        hints = {
          -- Charaters to use for hints (NOTE: make sure they don't collide with the navigation keymaps)
          ---@type string
          dictionary = "asdqwezxcrfvlpghio",
        },
        navigate = {
          -- Open buffer in vertical split
          open_vsplit = "|",

          -- Open buffer in split, based on `vim.opt.splitbelow`
          open_split = "-",
        },
      })

      local menu = require("snipe.menu")

      -- set additional keymaps when snipe menu is open
      local function set_keymaps(m)
        -- switch to last buffer
        vim.keymap.set("n", "<BS>", function()
          m:close()
          -- vim.cmd("b#") -- go to prev used buffer
          Snacks.picker.buffers({ filter = { cwd = true } })
        end, { nowait = true, buffer = m.buf })

        -- switch between tabs from the Snipe menu
        -- local function safe_tab_switch(n, m)
        --   return function()
        --     m:close()
        --     if vim.fn.tabpagenr("$") >= n then
        --       vim.cmd("tabnext " .. n)
        --     end
        --   end
        -- end
        -- vim.keymap.set("n", "1", function()
        --   m:close()
        --   vim.cmd("tabfirst")
        -- end, { nowait = true, buffer = m.buf })
        -- vim.keymap.set("n", "2", safe_tab_switch(2, m), { nowait = true, buffer = m.buf })
        -- vim.keymap.set("n", "3", safe_tab_switch(3, m), { nowait = true, buffer = m.buf })
        -- vim.keymap.set("n", "4", safe_tab_switch(4, m), { nowait = true, buffer = m.buf })
        -- vim.keymap.set("n", "5", safe_tab_switch(5, m), { nowait = true, buffer = m.buf })

        -- switch between Grapple.nvim tags from the Snipe menu
        local function safe_grapple_buffer_switch(n, m)
          return function()
            m:close()
            vim.cmd(string.format("Grapple select index=%d", n))
          end
        end
        vim.keymap.set("n", "1", safe_grapple_buffer_switch(1, m), { nowait = true, buffer = m.buf })
        vim.keymap.set("n", "2", safe_grapple_buffer_switch(2, m), { nowait = true, buffer = m.buf })
        vim.keymap.set("n", "3", safe_grapple_buffer_switch(3, m), { nowait = true, buffer = m.buf })
        vim.keymap.set("n", "4", safe_grapple_buffer_switch(4, m), { nowait = true, buffer = m.buf })
        vim.keymap.set("n", "5", safe_grapple_buffer_switch(5, m), { nowait = true, buffer = m.buf })
        vim.keymap.set("n", "m", function()
          m:close()
          require("grapple").toggle_tags()
        end, { desc = "Toggle tags menu" })
      end
      menu:add_new_buffer_callback(set_keymaps)
    end,
  },
}
