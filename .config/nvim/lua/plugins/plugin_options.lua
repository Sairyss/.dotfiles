-- Modifications to existing LazyVim plugin options
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
      opts.incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<S-b>",
          node_incremental = "<S-b>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      }
    end,
    -- keys = {
    --   {
    --     "<M-;>",
    --     function()
    --       local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
    --       ts_repeat_move.repeat_last_move_next()
    --     end,
    --   },
    --   {
    --     "<M-,>",
    --     function()
    --       local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
    --       ts_repeat_move.repeat_last_move_previous()
    --     end,
    --   },
    -- },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints = { enabled = false }
      opts.diagnostics = {
        virtual_text = false, -- disabled in favor of tiny-inline-diagnostic.nvim
      }

      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<C-.>", vim.lsp.buf.code_action }
      keys[#keys + 1] = { "<C-M-.>", LazyVim.lsp.action.source }
      keys[#keys + 1] = {
        "<F2>",
        function()
          local inc_rename = require("inc_rename")
          return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
        end,
        expr = true,
        desc = "Rename (inc-rename.nvim)",
        has = "rename",
      }
    end,
    -- opts = {
    --   inlay_hints = { enabled = false },
    --   diagnostics = {
    --     virtual_text = false, -- disabled in favor of tiny-inline-diagnostic.nvim
    --   },
    -- },

    -- add kulala-ls support
    -- config = function()
    --   local nvim_lsp = require("lspconfig")
    --   local capabilities = vim.lsp.protocol.make_client_capabilities()
    --   local servers = {
    --     "kulala_ls",
    --   }
    --   for _, lsp in ipairs(servers) do
    --     if nvim_lsp[lsp] ~= nil then
    --       if nvim_lsp[lsp].setup ~= nil then
    --         nvim_lsp[lsp].setup({
    --           capabilities = capabilities,
    --         })
    --       else
    --         vim.notify("LSP server " .. lsp .. " does not have a setup function", vim.log.levels.ERROR)
    --       end
    --     end
    --   end
    -- end,
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
      {
        "<leader><space>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<C-p>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<C-M-p>",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<C-M-/>",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume",
      },
      { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>ff", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>/", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sG", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
      { "<leader>sg", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sW", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
      {
        "<leader>sw",
        LazyVim.pick("grep_word", { root = false }),
        desc = "Visual selection or word (cwd)",
        mode = { "n", "x" },
      },
      { "<leader>fR", LazyVim.pick("oldfiles"), desc = "Recent" },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent({ filter = { cwd = true } })
        end,
        desc = "Recent (cwd)",
      },
    },
  },
  {
    "echasnovski/mini.ai",
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
    -- config = function(_, opts)
    --   require("mini.ai").setup(opts)
    --   LazyVim.on_load("which-key.nvim", function()
    --     vim.schedule(function()
    --       LazyVim.mini.ai_whichkey(opts)
    --     end)
    --   end)
    -- end,
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
  },

  ----- old -----

  -- {
  --   "ibhagwan/fzf-lua",
  --   cmd = "FzfLua",
  --   opts = function(_, opts)
  --     local config = require("fzf-lua.config")
  --
  --     config.defaults.keymap.fzf["ctrl-b"] = "half-page-up"
  --     config.defaults.keymap.fzf["ctrl-f"] = "half-page-down"
  --     config.defaults.keymap.fzf["ctrl-d"] = "preview-page-down"
  --     config.defaults.keymap.fzf["ctrl-u"] = "preview-page-up"
  --     config.defaults.keymap.builtin["<c-d>"] = "preview-page-down"
  --     config.defaults.keymap.builtin["<c-u>"] = "preview-page-up"
  --
  --     opts.defaults = {
  --       -- formatter = "path.dirname_first",
  --       formatter = "path.filename_first",
  --     }
  --     opts.oldfiles = {
  --       include_current_session = true,
  --     }
  --     opts.previewers = {
  --       builtin = {
  --         syntax_limit_b = 1024 * 100, -- 100KB
  --       },
  --     }
  --     opts.grep = {
  --       rg_glob = true, -- enable glob parsing
  --       glob_flag = "--iglob", -- case insensitive globs
  --       glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
  --     }
  --   end,
  --   keys = {
  --     -- { "<leader>/", LazyVim.pick("live_grep_glob"), desc = "Grep (Root Dir)" },
  --     { "<leader>/", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
  --     { "<leader>fR", "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
  --     { "<leader>fr", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
  --     { "<C-M-o>", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
  --     { "<C-p>", LazyVim.pick("files", { cwd = vim.uv.cwd() }), desc = "Find Files (cwd)" },
  --     { "<C-M-p>", "<cmd>FzfLua git_status<CR>", desc = "Status" },
  --     { "<C-M-/>", "<cmd>FzfLua resume<cr>", desc = "Resume" },
  --   },
  -- },
}
