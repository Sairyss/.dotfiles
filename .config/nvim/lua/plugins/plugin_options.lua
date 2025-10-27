-- Modifiuations to existing LazyVim plugin options
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "c",
        "diff",
        "html",
        "tsx",
        "typescript",
        "regex",
        "query",
        "rust",
        "sql",
        "prisma",
        "javascript",
        "jsdoc",
        "json",
        "query",
        "jsonc",
        "yaml",
        "http",
        "graphql",

        -- Golang
        "go",
        "gomod",
        "gowork",
        "gosum",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints = { enabled = false }
      opts.diagnostics = {
        virtual_text = false, -- disabled in favor of tiny-inline-diagnostic.nvim
      }

      opts.setup = {
        eslint = function()
          -- automatically fix linting errors on save
          vim.cmd([[
            autocmd BufWritePre *.tsx,*.ts,*.jsx,*.js EslintFixAll
          ]])
        end,
      }
      opts.servers = {
        ["*"] = {
          keys = {
            { "<C-.>", vim.lsp.buf.code_action, desc = "Code Action" },
            { "<C-M-.>", LazyVim.lsp.action.source, desc = "Source Action" },
          },
        },
      }
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    },
  },
  {
    "gbprod/yanky.nvim",
    desc = "Better Yank/Paste",
    opts = {
      highlight = { timer = 250 },
    },
    keys = {
      -- swap p and P in visual mode (won't copy selected text by default)
      { "P", "<Plug>(YankyPutAfter)", mode = { "x" }, desc = "Put Text After Cursor" },
      { "p", "<Plug>(YankyPutBefore)", mode = { "x" }, desc = "Put Text Before Cursor" },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        char = {
          -- remap ";" and "," to free those keys for other purposes
          keys = { "f", "F", "t", "T", [";"] = "<M-;>", [","] = "<M-,>" },
        },
      },
    },
  },
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<C-M-f>",
        function()
          if not vim.g.vscode then
            local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
            require("grug-far").toggle_instance({
              instanceName = "far",
              staticTitle = "Find and Replace",
              prefills = {
                filesFilter = ext and ext ~= "" and "*." .. ext or nil,
              },
            })
          end
        end,
        mode = { "n" },
        silent = true,
        desc = "Search and Replace",
      },
      {
        "<leader>sr",
        function()
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          require("grug-far").toggle_instance({
            instanceName = "far",
            staticTitle = "Find and Replace",
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      zen = {
        toggles = {
          dim = false,
        },
      },
      picker = {
        actions = require("trouble.sources.snacks").actions,
        win = {
          input = {
            keys = {
              ["<c-t>"] = {
                "trouble_open",
                mode = { "n", "i" },
              },
            },
          },
        },
      },
    },
    keys = {
      -- LSP
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
      },
      {
        "gD",
        function()
          Snacks.picker.lsp_declarations()
        end,
        desc = "Goto Declaration",
      },
      {
        "gr",
        function()
          Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "gI",
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "gy",
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "gai",
        function()
          Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
      },
      {
        "gao",
        function()
          Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
      },
      {
        "<leader>ss",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "LSP Workspace Symbols",
      },

      { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>/", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sG", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
      { "<leader>sg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sW", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
      {
        "<leader>sn",
        function()
          -- Yank the visual selection into "z register
          vim.cmd('normal! "zy')

          -- Get the contents of the z register
          local text = vim.fn.getreg("z")

          if not text or text == "" then
            return
          end

          -- Escape special characters for search
          text = vim.fn.escape(text, [[\/.*$^~[]])
          text = text:gsub("\n", [[\\n]])

          -- Feedkeys to open search prompt with the selection
          local keys = "/" .. text .. "\r"
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
        end,
        desc = "Search next from visual selection",
        mode = { "v" },
      },
      {
        "<leader>sw",
        LazyVim.pick("grep_word", { root = false }),
        desc = "Visual selection or word (cwd)",
        mode = { "n", "x" },
      },
      {
        "<leader>fR",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },
      {
        "<CR>r",
        function()
          Snacks.picker.recent({ filter = { cwd = true } })
        end,
        desc = "Recent Files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent({ filter = { cwd = true } })
        end,
        desc = "Recent (cwd)",
      },
      {
        "<C-/>",
        mode = { "n" },
        function()
          Snacks.terminal(nil, { cwd = LazyVim.root(), win = { position = "right", width = 0.4 } })
        end,
        { desc = "Terminal (Root Dir)" },
      },
      {
        "<leader>ft",
        mode = { "n" },
        function()
          Snacks.terminal(nil, { cwd = LazyVim.root(), win = { position = "right", width = 0.4 } })
        end,
        { desc = "Terminal (Root Dir)" },
      },
    },
  },
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
          d = { "%f[%d]%d+" }, -- digits
          -- override the default textobjects to work better with UPPER_SNAKE_CASE and so on
          e = {
            -- Lua 5.1 character classes and the undocumented frontier pattern:
            -- https://www.lua.org/manual/5.1/manual.html#5.4.1
            -- http://lua-users.org/wiki/FrontierPattern
            -- note: when I say "letter" I technically mean "letter or digit"
            {
              -- Matches a single uppercase letter followed by 1+ lowercase letters.
              -- This covers:
              -- - PascalCaseWords (or the latter part of camelCaseWords)
              "%u[%l%d]+%f[^%l%d]", -- An uppercase letter, 1+ lowercase letters, to end of lowercase letters

              -- Matches lowercase letters up until not lowercase letter.
              -- This covers:
              -- - start of camelCaseWords (just the `camel`)
              -- - snake_case_words in lowercase
              -- - regular lowercase words
              "%f[^%s%p][%l%d]+%f[^%l%d]", -- after whitespace/punctuation, 1+ lowercase letters, to end of lowercase letters
              "^[%l%d]+%f[^%l%d]", -- after beginning of line, 1+ lowercase letters, to end of lowercase letters

              -- Matches uppercase or lowercase letters up until not letters.
              -- This covers:
              -- - SNAKE_CASE_WORDS in uppercase
              -- - Snake_Case_Words in titlecase
              -- - regular UPPERCASE words
              -- (it must be both uppercase and lowercase otherwise it will
              -- match just the first letter of PascalCaseWords)
              "%f[^%s%p][%a%d]+%f[^%a%d]", -- after whitespace/punctuation, 1+ letters, to end of letters
              "^[%a%d]+%f[^%a%d]", -- after beginning of line, 1+ letters, to end of letters
            },
            "^().*()$",
          }, -- g = LazyVim.mini.ai_buffer, -- buffer
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end,
  },
  {
    {
      "nvim-lualine/lualine.nvim",
      opts = {
        -- optimize lualine performance https://github.com/LazyVim/LazyVim/discussions/326
        refresh = {
          statusline = 1500,
          tabline = 1500,
          winbar = 1500,
        },
        sections = {
          --   lualine_a = { "branch" },
          --   lualine_b = {},
          lualine_c = {
            LazyVim.lualine.root_dir(),
            { "diagnostics" },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { LazyVim.lualine.pretty_path() },
          },
          --   lualine_x = {},
          --   lualine_y = {
          --     { "progress", separator = " ", padding = { left = 1, right = 0 } },
          --     { "location", padding = { left = 0, right = 1 } },
          --   },
          lualine_z = {},
        },
      },
    },
    {
      "mistweaverco/kulala.nvim",
      ft = "http",
      keys = {
        { "<C-M-r>", "<cmd>lua require('kulala').run()<cr>", desc = "Send the request", ft = "http" },
        { "<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>", desc = "Send the request", ft = "http" },
      },
      opts = {
        default_env = "local",
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    opts = {
      task_list = {
        min_height = 14,
        -- direction = "right",
      },
    },
    keys = {
      {
        "<leader>or",
        function()
          local overseer = require("overseer")
          local tasks = overseer.list_tasks({ recent_first = true })
          if vim.tbl_isempty(tasks) then
            vim.notify("No tasks found", vim.log.levels.WARN)
          else
            overseer.run_action(tasks[1], "restart")
          end
        end,
        mode = { "n" },
        silent = true,
        desc = "Rerun last task",
      },
      {
        "<leader>os",
        function()
          local overseer = require("overseer")
          local tasks = overseer.list_tasks({ recent_first = true })
          if vim.tbl_isempty(tasks) then
            vim.notify("No tasks found", vim.log.levels.WARN)
          else
            overseer.run_action(tasks[1], "stop")
          end
        end,
        mode = { "n" },
        silent = true,
        desc = "Stop last task",
      },
    },
    config = function(_, opts)
      require("overseer").setup(opts)
      require("overseer").register_template({
        name = "npm run test {name}",
        params = {
          name = {
            type = "string",
            -- Optional fields that are available on any type
            name = "Test name",
            desc = "Test to run",
            order = 1, -- determines order of parameters in the UI
            optional = false,
          },
        },
        builder = function(params)
          return {
            cmd = { "npm" },
            args = { "run", "test", params.name },
          }
        end,
        condition = {
          callback = function(search)
            return vim.fn.filereadable(vim.fn.findfile("package.json", search.dir .. ";")) == 1
          end,
        },
      })
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    enabled = false,
  -- stylua: ignore
  keys = {
    { "<leader>Qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>QS", function() require("persistence").select() end,desc = "Select Session" },
    { "<leader>Ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>Qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      defaults = {
        path_display = {
          "smart",
        },
        layout_config = {
          prompt_position = "top",
        },
        sorting_strategy = "ascending",
      },
    },
  },
}
