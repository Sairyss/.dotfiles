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
      vim.diagnostic.config({ virtual_text = false })
      vim.diagnostic.open_float = require("tiny-inline-diagnostic.override").open_float
    end,
  },
  {
    "bngarren/checkmate.nvim",
    ft = "markdown", -- Lazy loads for Markdown files matching patterns in 'files'
    opts = {
      -- your configuration here
      -- or leave empty to use defaults

      -- -- Regular markers to avoid conflicts with render-markdown.nvim
      -- todo_markers = {
      --   unchecked = "[ ]",
      --   checked = "[x]",
      -- },
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
  --   -- contextual information above functions
  --   "oribarilan/lensline.nvim",
  --   -- tag = "1.0.0", -- or: branch = 'release/1.x' for latest non-breaking updates
  --   branch = "release/1.x",
  --   event = "LspAttach",
  --   config = function()
  --     require("lensline").setup()
  --   end,
  -- },
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function(_, opts)
      require("codediff").setup(opts)

      -- WORKAROUND for a CodeDiff bug (seen in v4.0.6, commit 09d9ebe): browsing the file list /
      -- history panel sometimes moves the cursor into the diff pane. In
      -- lua/codediff/ui/view/side_by_side/update.lua, M.update restores focus inside the render
      -- callback, but reload_side() runs after it and calls :edit, which focuses the diff pane.
      -- When the render runs immediately (e.g. untracked files), nothing restores focus afterwards.
      -- Remove this wrapper once CodeDiff fixes it: comment it out, browse with j/k past an
      -- untracked file, and check the cursor stays in the list.
      local view = require("codediff.ui.view")
      local panel_filetypes = { ["codediff-explorer"] = true, ["codediff-history"] = true }
      for _, name in ipairs({ "show", "update" }) do
        local original = view[name]
        view[name] = function(...)
          local win = vim.api.nvim_get_current_win()
          local from_panel = panel_filetypes[vim.bo[vim.api.nvim_win_get_buf(win)].filetype]
          local result = original(...)
          if from_panel and vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() ~= win then
            vim.api.nvim_set_current_win(win)
          end
          return result
        end
      end
    end,
    init = function()
      -- "e" in the CodeDiff file list opens the file (same as the built-in gf) at its first hunk
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codediff-explorer",
        callback = function(ev)
          vim.keymap.set("n", "e", function()
            local session = require("codediff.ui.lifecycle").get_session(vim.api.nvim_get_current_tabpage())
            local changes = session and session.stored_diff_result and session.stored_diff_result.changes
            local first_line = changes and changes[1] and changes[1].modified.start_line

            vim.cmd("normal gf")

            if first_line and vim.bo.filetype ~= "codediff-explorer" then
              first_line = math.max(1, math.min(first_line, vim.api.nvim_buf_line_count(0)))
              vim.api.nvim_win_set_cursor(0, { first_line, 0 })
              vim.cmd("normal! zz")
            end
          end, { buffer = ev.buf, desc = "CodeDiff: open file at first hunk" })

          -- "Y" copies the selected file's path relative to the git root
          vim.keymap.set("n", "Y", function()
            local explorer = require("codediff.ui.lifecycle").get_panel_view(vim.api.nvim_get_current_tabpage())
            local node = explorer and explorer.tree and explorer.tree:get_node()
            local path = node and node.data and node.data.path
            if not path or path == "" then
              return
            end
            vim.fn.setreg("+", path)
            vim.notify("Copied: " .. path)
          end, { buffer = ev.buf, desc = "CodeDiff: copy relative path" })
        end,
      })

      -- History panel: show the diff for the commit/file under the cursor as you move (no <CR> needed)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codediff-history",
        callback = function(ev)
          local timer = assert(vim.uv.new_timer())
          vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = ev.buf,
            callback = function()
              timer:stop()
              timer:start(
                80,
                0,
                vim.schedule_wrap(function()
                  local history = require("codediff.ui.lifecycle").get_panel_view(vim.api.nvim_get_current_tabpage())
                  if not history or history.bufnr ~= vim.api.nvim_get_current_buf() then
                    return
                  end
                  local node = history.tree:get_node()
                  local data = node and node.data
                  local current = history.data
                  if not data then
                    return
                  end
                  if data.type == "commit" and history.is_single_file_mode then
                    if data.hash ~= current.current_commit then
                      history.on_file_select({
                        path = data.file_path or current.opts.file_path,
                        commit_hash = data.hash,
                        git_root = current.git_root,
                      })
                    end
                  elseif data.type == "file" then
                    if data.commit_hash ~= current.current_commit or data.path ~= current.current_file then
                      history.on_file_select(data)
                    end
                  end
                end)
              )
            end,
          })
          vim.api.nvim_create_autocmd("BufWipeout", {
            buffer = ev.buf,
            once = true,
            callback = function()
              timer:stop()
              timer:close()
            end,
          })
        end,
      })
    end,
    opts = {
      diff = {
        compact = true, -- Fold unchanged regions, show only hunks + context (toggle with gc)
        compact_context_lines = 3, -- Context lines around each hunk in compact mode
        layout = "inline", -- "side-by-side" or "inline"; toggle with t
        gutter_signs = {
          insert_text = "＋",
          delete_text = "－",
          highlight_numbers = true,
          changed_priority = 100,
          unchanged_priority = nil,
        },
      },
      explorer = {
        position = "left",
        width = 40,
        auto_open_on_cursor = true, -- j/k in the file list updates the diff
      },
      keymaps = {
        view = {
          next_hunk = "]h", -- Jump to next change
          prev_hunk = "[h", -- Jump to previous change
          close_on_open_in_prev_tab = true, -- close CodeDiff after gf opens the file
        },
      },
    },
    keys = {
      {
        "<leader>gd",
        ":CodeDiff<CR>",
        desc = "CodeDiff",
        silent = true,
      },
      {
        "<leader>gC",
        ":CodeDiff master<CR>",
        desc = "CodeDiff master",
        silent = true,
      },
      {
        "<leader>gm",
        ":CodeDiff file master HEAD<CR>",
        desc = "CodeDiff file master",
        silent = true,
      },
      {
        "<leader>gf",
        ":CodeDiff history %<CR>",
        desc = "CodeDiff current file history",
        silent = true,
      },
      {
        "<leader>gH",
        ":CodeDiff history<CR>",
        desc = "CodeDiff history",
        silent = true,
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
}
