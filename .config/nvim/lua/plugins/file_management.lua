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
}
