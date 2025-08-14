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
    -- keys = {
    -- 	{
    -- 		"<leader><space>",
    -- 		function()
    -- 			require("fff").find_files() -- or find_in_git_root() if you only want git files
    -- 		end,
    -- 		desc = "Open file picker",
    -- 	},
    -- },
  },
}
