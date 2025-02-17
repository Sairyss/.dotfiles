-- Modifications to existing LazyVim plugin options
return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = function(_, opts)
      local config = require("fzf-lua.config")

      config.defaults.keymap.fzf["ctrl-b"] = "half-page-up"
      config.defaults.keymap.fzf["ctrl-f"] = "half-page-down"
      config.defaults.keymap.fzf["ctrl-d"] = "preview-page-down"
      config.defaults.keymap.fzf["ctrl-u"] = "preview-page-up"
      config.defaults.keymap.builtin["<c-d>"] = "preview-page-down"
      config.defaults.keymap.builtin["<c-u>"] = "preview-page-up"

      opts.defaults = {
        -- formatter = "path.dirname_first",
        formatter = "path.filename_first",
      }
      opts.oldfiles = {
        include_current_session = true,
      }
      opts.previewers = {
        builtin = {
          syntax_limit_b = 1024 * 100, -- 100KB
        },
      }
      opts.grep = {
        rg_glob = true, -- enable glob parsing
        glob_flag = "--iglob", -- case insensitive globs
        glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
      }
    end,
    keys = {
      -- { "<leader>/", LazyVim.pick("live_grep_glob"), desc = "Grep (Root Dir)" },
      { "<leader>/", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>fR", "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
      { "<leader>fr", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
      { "<C-M-o>", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
      { "<C-p>", LazyVim.pick("files", { cwd = vim.uv.cwd() }), desc = "Find Files (cwd)" },
      { "<C-M-p>", "<cmd>FzfLua git_status<CR>", desc = "Status" },
      { "<C-M-/>", "<cmd>FzfLua resume<cr>", desc = "Resume" },
    },
  },
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
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      diagnostics = {
        virtual_text = false, -- disabled in favor of tiny-inline-diagnostic.nvim
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- add a keymap
      keys[#keys + 1] = { "<C-.>", vim.lsp.buf.code_action }
      keys[#keys + 1] = { "<C-M-.>", LazyVim.lsp.action.source }
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
          -- remap ; and , to M-; and M-, to free those keys for other purposes
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
    },
  },
}
