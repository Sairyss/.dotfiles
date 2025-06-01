-- plugins to simulate jupyter notebook / quarto in neovim
return {
  {
    "quarto-dev/quarto-nvim",
    ft = "quarto",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      codeRunner = {
        enabled = true,
        default_method = "iron", -- "molten", "slime", "iron" or <function>
        ft_runners = {}, -- filetype to runner, ie. `{ python = "molten" }`.
        -- Takes precedence over `default_method`
        never_run = { "yaml", "json" }, -- filetypes which are never sent to a code runner
      },
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
    opts = {
      -- Your options go here
      -- name = "venv",
      -- auto_refresh = false
    },
    event = "VeryLazy", -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
    -- keys = {
    --   -- Keymap to open VenvSelector to pick a venv.
    --   { "<leader>vs", "<cmd>VenvSelect<cr>" },
    --   -- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
    --   { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
    -- },
  },
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty", -- whatever backend you would like to use
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
  {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    build = ":UpdateRemotePlugins",
    init = function()
      -- this is an example, not a default. Please see the readme for more configuration options
      vim.g.molten_output_win_max_height = 15
      vim.g.molten_auto_open_output = true
      vim.g.molten_image_provider = "image.nvim"
    end,
    keys = {
      {
        "<leader>ri",
        function()
          local quarto_cfg = require("quarto.config").config
          quarto_cfg.codeRunner.default_method = "molten"
          vim.cmd([[MoltenInit]])
        end,
        desc = "Start Molten",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rd",
        function()
          local quarto_cfg = require("quarto.config").config
          quarto_cfg.codeRunner.default_method = "iron" -- switch to iron when molten stops. this allows us to use both
          vim.cmd([[MoltenDeinit]])
        end,
        desc = "Stop Molten",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rr",
        ":QuartoSend<CR>",
        desc = "Quarto execute cell",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rR",
        ":QuartoSendAll<CR>",
        desc = "Quarto execute all",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rp",
        ":MoltenImagePopup<CR>",
        desc = "Molten image popup",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rb",
        ":MoltenOpenInBrowser<CR>",
        desc = "Molten open in browser",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rh",
        ":MoltenHideOutput<CR>",
        desc = "Molten hide output",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rs",
        ":noautocmd MoltenEnterOutput<CR>",
        desc = "Molten show/enter output",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rQ",
        ":QuartoPreview<CR>",
        desc = "Quarto preview",
        ft = "quarto",
        silent = true,
      },
      {
        "<leader>rv",
        ":VenvSelect<CR>",
        desc = "Select venv",
        ft = "quarto",
        silent = true,
      },
    },
  },
  {
    "Vigemus/iron.nvim",
    config = function()
      local common = require("iron.fts.common")
      local view = require("iron.view")
      local iron = require("iron.core")
      iron.setup({
        config = {
          -- Whether a repl should be discarded or not
          scratch_repl = true,
          -- Your repl definitions come here
          repl_definition = {
            sh = {
              -- Can be a table or a function that
              -- returns a table (see below)
              command = { "zsh" },
            },
            python = {
              command = { "python3" }, -- or { "ipython", "--no-autoindent" }
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
            },
          },
          -- set the file type of the newly created repl to ft
          -- bufnr is the buffer id of the REPL and ft is the filetype of the
          -- language being used for the REPL.
          repl_filetype = function(bufnr, ft)
            return ft
            -- or return a string name such as the following
            -- return "iron"
          end,
          -- How the repl window will be displayed
          -- See below for more information
          -- repl_open_cmd = view.bottom(20),
          repl_open_cmd = view.split.rightbelow("%30"),

          -- repl_open_cmd can also be an array-style table so that multiple
          -- repl_open_commands can be given.
          -- When repl_open_cmd is given as a table, the first command given will
          -- be the command that `IronRepl` initially toggles.
          -- Moreover, when repl_open_cmd is a table, each key will automatically
          -- be available as a keymap (see `keymaps` below) with the names
          -- toggle_repl_with_cmd_1, ..., toggle_repl_with_cmd_k
          -- For example,
          --
          -- repl_open_cmd = {
          --   view.split.vertical.rightbelow("%40"), -- cmd_1: open a repl to the right
          --   view.split.rightbelow("%25")  -- cmd_2: open a repl below
          -- }
        },
        -- Iron doesn't set keymaps by default anymore.
        -- You can set them here or manually add keymaps to the functions in iron.core
        -- keymaps = {
        --   toggle_repl = "<space>rr", -- toggles the repl open and closed.
        --   -- If repl_open_command is a table as above, then the following keymaps are
        --   -- available
        --   -- toggle_repl_with_cmd_1 = "<space>rv",
        --   -- toggle_repl_with_cmd_2 = "<space>rh",
        --   restart_repl = "<space>rR", -- calls `IronRestart` to restart the repl
        --   send_motion = "<space>sc",
        --   visual_send = "<space>sc",
        --   send_file = "<space>sf",
        --   send_line = "<space>sl",
        --   send_paragraph = "<space>sp",
        --   send_until_cursor = "<space>su",
        --   send_mark = "<space>sm",
        --   send_code_block = "<space>sb",
        --   send_code_block_and_move = "<space>sn",
        --   mark_motion = "<space>mc",
        --   mark_visual = "<space>mc",
        --   remove_mark = "<space>md",
        --   cr = "<space>s<cr>",
        --   interrupt = "<space>s<space>",
        --   exit = "<space>sq",
        --   clear = "<space>cl",
        -- },
        -- If the highlight is on, you can change how it looks
        -- For the available options, check nvim_set_hl
        highlight = {
          italic = true,
        },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      })
    end,
  },
  { -- directly open ipynb files as quarto docuements
    -- and convert back behind the scenes
    "GCBallesteros/jupytext.nvim",
    opts = {
      custom_language_formatting = {
        python = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
        r = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
      },
    },
  },
}
