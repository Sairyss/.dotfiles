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
    keys = {
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
        "<leader>rQ",
        ":QuartoPreview<CR>",
        desc = "Quarto preview",
        ft = "quarto",
        silent = true,
      },
      {
        "<C-M-r>",
        ":QuartoSendAll<CR>",
        desc = "Quarto execute all",
        ft = "quarto",
        silent = true,
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

    keys = {
      {
        "<leader>re",
        ":VenvSelect<CR>",
        ft = { "python", "quarto" },
        desc = "Env select (venv)",
        silent = true,
      },
    },
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
        "<leader>rmi",
        function()
          local quarto_cfg = require("quarto.config").config
          quarto_cfg.codeRunner.default_method = "molten"
          vim.cmd([[MoltenInit]])
        end,
        desc = "Initialize Molten",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rmd",
        function()
          local quarto_cfg = require("quarto.config").config
          quarto_cfg.codeRunner.default_method = "iron" -- switch to iron when molten stops. this allows us to use both
          vim.cmd([[MoltenDeinit]])
        end,
        desc = "Deactivate Molten",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rV",
        ":MoltenEvaluateVisual<CR>",
        desc = "Molten evaluate visual",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rL",
        ":MoltenEvaluateVisual<CR>",
        desc = "Molten evaluate line",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rmp",
        ":MoltenImagePopup<CR>",
        desc = "Molten image popup",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rmb",
        ":MoltenOpenInBrowser<CR>",
        desc = "Molten open in browser",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rmh",
        ":MoltenHideOutput<CR>",
        desc = "Molten hide output",
        ft = { "python", "quarto" },
        silent = true,
      },
      {
        "<leader>rms",
        ":noautocmd MoltenEnterOutput<CR>",
        desc = "Molten show/enter output",
        ft = { "python", "quarto" },
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
              command = { "ipython", "--no-autoindent" },
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
        keymaps = {
          toggle_repl = "<space>rt", -- toggles the repl open and closed.
          -- If repl_open_command is a table as above, then the following keymaps are
          -- available
          -- toggle_repl_with_cmd_1 = "<space>rv",
          -- toggle_repl_with_cmd_2 = "<space>rh",
          restart_repl = "<space>rR", -- calls `IronRestart` to restart the repl
          send_motion = "<space>rv",
          visual_send = "<space>rv",
          send_file = "<space>rf",
          send_line = "<space>rl",
          send_paragraph = "<space>rp",
          send_until_cursor = "<space>ru",
          send_code_block = "<space>rb",
          send_code_block_and_move = "<space>rn",
          -- send_mark = "<space>rm",
          -- mark_motion = "<space>mc",
          -- mark_visual = "<space>mc",
          -- remove_mark = "<space>md",
          -- cr = "<space>s<cr>",
          -- interrupt = "<space>s<space>",
          exit = "<space>rq",
          clear = "<space>rc",
        },
        -- If the highlight is on, you can change how it looks
        -- For the available options, check nvim_set_hl
        highlight = {
          italic = true,
        },
        ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
      })
    end,
    keys = {
      {
        mode = { "n" },
        silent = true,
        "<C-M-r>",
        '<Cmd>lua require("iron").core.send(vim.api.nvim_buf_get_option(0,"ft"), vim.api.nvim_buf_get_lines(0, 0, -1, false))<Cr>',
      },
    },
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
