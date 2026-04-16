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
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      -- this will download prebuild binary or try to use existing rustup toolchain to build from source
      -- (if you are using lazy you can use gb for rebuilding a plugin if needed)
      require("fff.download").download_or_build_binary()
    end,
    -- or if you are using nixos
    -- build = "nix run .#release",
    opts = {
      -- pass here all the options
      layout = {
        prompt_position = "top", -- Position of prompt ('top' or 'bottom')
        preview_position = "right", -- Position of preview ('right' or 'left')
        -- preview_size = 0.4, -- Width of preview pane
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
  {
    "2kabhishek/seeker.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = { "Seeker" },
    keys = {
      { "<leader>fs", ":Seeker files<CR>", desc = "Seek Files" },
      -- { '<leader>ff', ':Seeker git_files<CR>', desc = 'Seek Git Files' },
      -- { '<leader>fg', ':Seeker grep<CR>', desc = 'Seek Grep' },
      -- { '<leader>fw', ':Seeker grep_word<CR>', desc = 'Seek Grep Word' },
    },
    opts = {}, -- Required unless you call seeker.setup() manually, add your configs here
  },
}
