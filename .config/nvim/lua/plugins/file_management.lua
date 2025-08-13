-- File management plugins configuration
return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = false,
      float = {
        padding = 2,
        max_width = 0.8,
        max_height = 0.8,
      },
    },
    keys = {
      {
        "<leader>fo",
        function()
          require("oil").toggle_float()
          vim.api.nvim_buf_set_keymap(0, "n", "<Esc>", "<cmd>lua require('oil').close()<cr>", { silent = true })
        end,
        desc = "Oil.nvim",
      },
    },
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },
  -- {
  --   "benomahony/oil-git.nvim",
  --   dependencies = { "stevearc/oil.nvim" },
  --   -- No opts or config needed! Works automatically
  -- },
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      -- 👇 in this section, choose your own keymappings!
      {
        "<leader>fy",
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        -- Open in the current working directory
        "<leader>fY",
        "<cmd>Yazi cwd<cr>",
        desc = "Open yazi in working directory",
      },
      {
        "<c-up>",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume the last yazi session",
      },
    },
    opts = {
      -- if you want to open yazi instead of netrw, see below for more info
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
    },
  },
  {
    "dmtrKovalenko/fff.nvim",
    build = "cargo build --release",
    -- or if you are using nixos
    -- build = "nix run .#release",
    opts = {
      -- pass here all the options
      layout = {
        prompt_position = "top", -- Position of prompt ('top' or 'bottom')
        preview_position = "right", -- Position of preview ('right' or 'left')
        preview_width = 0.4, -- Width of preview pane
        height = 0.8, -- Window height
        width = 0.8, -- Window width
      },
    },
    keys = {
      {
        "<leader><space>",
        function()
          require("fff").find_files() -- or find_in_git_root() if you only want git files
        end,
        desc = "Open file picker",
      },
    },
  },
  {
    "A7Lavinraj/fyler.nvim",
    dependencies = { "echasnovski/mini.icons" },
    branch = "stable",
    opts = {
      git_status = true,
    }, -- check the default options in the README.md
    keys = {
      {
        "<leader>fO",
        function()
          require("fyler").open({ cwd = vim.fn.getcwd() })
        end,
        desc = "Fyler.nvim in current working directory",
      },
    },
  },
}
