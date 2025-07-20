-- Custom added plugins
return {
  {
    "abecodes/tabout.nvim",
    lazy = false,
    config = function()
      require("tabout").setup({
        tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true, -- shift content if tab out is not possible
        act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = "<C-d>", -- reverse shift default action,
        enable_backwards = true, -- well ...
        completion = true, -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
          { open = "<", close = ">" },
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {}, -- tabout will ignore these filetypes
      })
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      -- "L3MON4D3/LuaSnip",
      -- "hrsh7th/nvim-cmp",
    },
  },
  {
    -- https://github.com/jake-stewart/multicursor.nvim
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    keys = {
      {
        "<C-esc>",
        mode = { "n" },
        function()
          local mc = require("multicursor-nvim")
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          elseif mc.hasCursors() then
            mc.clearCursors()
          else
            -- pcall(function() -- clear flash.nvim highlights
            --   require("flash.repeat").get_state("jump"):hide()
            --   local c = require("flash.plugins.char")
            --   c.jumping = false
            --   if c.state then
            --     c.state:hide()
            --   end
            --   c.state = nil
            --   c.jump_labels = false
            -- end)
            --
            -- vim.cmd("noh") -- Clear search highlight (hlsearch)
            --
            -- Default <esc> handler.
          end
        end,
      },
      -- add cursor by matching word/selection
      {
        "<C-n>",
        mode = { "n", "x" },
        function()
          local mc = require("multicursor-nvim")
          mc.matchAddCursor(1)
        end,
      },
      -- add cursor above/below
      {
        "<C-M-k>",
        function()
          local mc = require("multicursor-nvim")
          mc.lineAddCursor(-1)
        end,
      },
      {
        "<C-M-j>",
        function()
          local mc = require("multicursor-nvim")
          mc.lineAddCursor(1)
        end,
      },
      -- Add and remove cursors with left click.
      {
        "<C-M-leftmouse>",
        function()
          local mc = require("multicursor-nvim")
          mc.handleMouse()
        end,
      },
      -- Easy way to add and remove cursors using the main cursor.
      {
        "<c-q>",
        mode = { "n", "x" },
        function()
          local mc = require("multicursor-nvim")
          mc.toggleCursor()
        end,
      },
    },
    config = function()
      require("multicursor-nvim").setup()

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { link = "Cursor" })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end,
  },
  {
    "aileot/emission.nvim",
    event = "VeryLazy",
    opts = {
      highlight = {
        duration = 500, -- milliseconds
      },
      removed = {
        -- Set it to false to disable highlights on removed texts regardless of
        -- the other filter options.
        enabled = false,
      },
    },
  },
  {
    "smjonas/live-command.nvim",
    -- live-command supports semantic versioning via Git tags
    -- tag = "2.*",
    config = function()
      require("live-command").setup({
        commands = {
          Norm = { cmd = "norm" },
        },
      })
    end,
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy", -- Or `LspAttach`
    priority = 1000, -- needs to be loaded in first
    config = function()
      require("tiny-inline-diagnostic").setup({
        options = {
          -- Enable diagnostic message on all lines.
          multilines = true,

          -- If multiple diagnostics are under the cursor, display all of them.
          multiple_diag_under_cursor = true,

          -- Show all diagnostics on the cursor line.
          show_all_diags_on_cursorline = false,
        },
      })
    end,
  },
  {
    "bngarren/checkmate.nvim",
    ft = "markdown", -- Lazy loads for Markdown files matching patterns in 'files'
    opts = {
      -- your configuration here
      -- or leave empty to use defaults
    },
    keys = {
      {
        "<CR>",
        desc = "Toggle todo item",
        silent = true,
        mode = { "n", "v" },
        ft = { "markdown" },
        function()
          local checkmate = require("checkmate")
          if checkmate.is_running() then
            checkmate.toggle()
          end
        end,
      },
      {
        "<C-CR>",
        desc = "Create todo item",
        silent = true,
        mode = { "n", "v" },
        ft = { "markdown" },
        function()
          local checkmate = require("checkmate")
          if checkmate.is_running() then
            checkmate.create()
          end
        end,
      },
    },
  },
  -- {
  --   "obsidian-nvim/obsidian.nvim",
  --   version = "*", -- recommended, use latest release instead of latest commit
  --   lazy = true,
  --   ft = "markdown",
  --   -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  --   -- event = {
  --   --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   --   -- refer to `:h file-pattern` for more examples
  --   --   "BufReadPre path/to/my-vault/*.md",
  --   --   "BufNewFile path/to/my-vault/*.md",
  --   -- },
  --   dependencies = {
  --     -- Required.
  --     "nvim-lua/plenary.nvim",
  --   },
  --   opts = {
  --     workspaces = {
  --       {
  --         name = "cs-notes",
  --         path = "/mnt/nvme0n1p3/Code/cs-notes/",
  --       },
  --     },
  --     templates = {
  --       folder = "/mnt/nvme0n1p3/Code/cs-notes/Templates/",
  --       date_format = "%Y-%m-%d",
  --       time_format = "%H:%M",
  --     },
  --   },
  -- },

  -- old --

  -- {
  --   "Bekaboo/dropbar.nvim",
  --   -- optional, but required for fuzzy finder support
  --   -- dependencies = {
  --   -- "nvim-telescope/telescope-fzf-native.nvim",
  --   -- build = "make",
  --   -- },
  --   enabled = false,
  --   config = function()
  --     local dropbar_api = require("dropbar.api")
  --     vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
  --     -- vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
  --     -- vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
  --   end,
  -- },
  -- {
  --   "https://git.sr.ht/~swaits/zellij-nav.nvim",
  --   lazy = true,
  --   event = "VeryLazy",
  --   keys = {
  --     { "<c-h>", "<cmd>silent! ZellijNavigateLeftTab<cr>", { silent = true, desc = "navigate left or tab" } },
  --     { "<c-j>", "<cmd>silent! ZellijNavigateDown<cr>", { silent = true, desc = "navigate down" } },
  --     { "<c-k>", "<cmd>silent! ZellijNavigateUp<cr>", { silent = true, desc = "navigate up" } },
  --     { "<c-l>", "<cmd>silent! ZellijNavigateRightTab<cr>", { silent = true, desc = "navigate right or tab" } },
  --   },
  --   opts = {},
  -- },
  -- {
  --   "michaelb/sniprun",
  --   branch = "master",
  --   build = "sh install.sh",
  --   -- do 'sh install.sh 1' if you want to force compile locally
  --   -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
  --   config = function()
  --     require("sniprun").setup({
  --       -- your options
  --       display = {
  --         -- "Classic", --# display results in the command-line  area
  --         "VirtualTextOk", --# display ok results as virtual text (multiline is shortened)
  --
  --         -- "VirtualText",             --# display results as virtual text
  --         -- "TempFloatingWindow",      --# display results in a floating window
  --         -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText[Ok/Err]
  --         "Terminal", --# display results in a vertical split
  --         -- "TerminalWithCode",        --# display results and code history in a vertical split
  --         -- "NvimNotify",              --# display with the nvim-notify plugin
  --         -- "Api"                      --# return output to a programming interface
  --       },
  --       display_options = {
  --         terminal_scrollback = vim.o.scrollback, --# change terminal display scrollback lines
  --         terminal_line_number = false, --# whether show line number in terminal window
  --         terminal_signcolumn = false, --# whether show signcolumn in terminal window
  --         terminal_position = "horizontal", --# "vertical" or "horizontal", to open as horizontal split instead of vertical split
  --         terminal_width = 45, --# change the terminal display option width (if vertical)
  --         terminal_height = 20, --# change the terminal display option height (if horizontal)
  --         notification_timeout = 5, --# timeout for nvim_notify output
  --       },
  --     })
  --   end,
  --   keys = {
  --     {
  --       mode = { "n" },
  --       silent = true,
  --       "<C-M-r>",
  --       ":let b:caret=winsaveview()<CR>|:%SnipRun<CR>|:call winrestview(b:caret)<CR>",
  --     },
  --   },
  -- },
}
