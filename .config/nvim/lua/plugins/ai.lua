return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false, -- set this if you want to always pull the latest change
    opts = {
      provider = "gemini",
      auto_suggestions_provider = "gemini",
      behaviour = {
        auto_suggestions = false,
      },
      input = {
        provider = "snacks",
        provider_opts = {
          title = "Avante Input",
          icon = " ",
        },
      },
      providers = {
        copilot = {
          endpoint = "https://api.githubcopilot.com",
          model = "gpt-4o-2024-11-20",
          proxy = nil, -- [protocol://]host[:port] Use this proxy
          allow_insecure = false, -- Allow insecure server connections
          -- disable_tools = true,
          extra_request_body = {
            temperature = 0,
            max_completion_tokens = 8192,
          },
        },
        gemini = {
          model = "gemini-2.5-flash",
          -- temperature = 0,
          temperature = 0,
          max_tokens = 8192,
          -- max_tokens = 10000,
          -- disable_tools = true,
          extra_request_body = {
            temperature = 0,
            max_tokens = 8192,
            max_completion_tokens = 8192,
            -- max_completion_tokens = 10000,
            -- max_tokens = 10000,
            -- disable_tools = true,
          },
        },
        openai = {
          endpoint = "https://api.openai.com/v1",
          model = "gpt-4o",
          disable_tools = true,
          extra_request_body = {
            temperature = 0,
            max_completion_tokens = 8192,
            reasoning_effort = "medium",
          },
        },
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      -- "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      -- "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      -- "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      require("minuet").setup({
        provider = "gemini",
        blink = {
          enable_auto_complete = true,
        },
        provider_options = {
          gemini = {
            model = "gemini-2.5-flash",
            -- system = "see [Prompt] section for the default value",
            -- few_shots = "see [Prompt] section for the default value",
            -- chat_input = "See [Prompt Section for default value]",
            stream = true,
            api_key = "GEMINI_API_KEY",
            end_point = "https://generativelanguage.googleapis.com/v1beta/models",
            optional = {
              generationConfig = {
                maxOutputTokens = 512,
                -- When using `gemini-2.5-flash`, it is recommended to entirely
                -- disable thinking for faster completion retrieval.
                thinkingConfig = {
                  thinkingBudget = 0,
                },
              },
            },
          },
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "Kaiser-Yang/blink-cmp-avante",
      -- ... Other dependencies
    },
    config = function(_, opts)
      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        ["<A-y>"] = require("minuet").make_blink_map(),
      })
      require("blink-cmp").setup(opts)
    end,
    opts = {
      sources = {
        default = { "avante", "minuet", "lsp", "path", "snippets", "buffer" },
        providers = {
          avante = {
            module = "blink-cmp-avante",
            name = "Avante",
            opts = {
              -- options for blink-cmp-avante
            },
          },
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            -- Should match minuet.config.request_timeout * 1000,
            -- since minuet.config.request_timeout is in seconds
            timeout_ms = 3000,
            score_offset = 50, -- Gives minuet higher priority among suggestions
          },
        },
      },
    },
    -- keymap = {
    --   -- Manually invoke minuet completion.
    --   -- ["<A-y>"] = require("minuet").make_blink_map(),
    -- },
  },
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    ------@type opencode.Config
    ---opts = {
    ---  -- Your configuration, if any
    ---},
  -- stylua: ignore
    keys = {
      { '<leader>At', function() require('opencode').toggle() end, desc = 'Toggle opencode', },
      { '<leader>Aa', function() require('opencode').ask() end, desc = 'Ask opencode', mode = { 'n', 'v' }, },
      { '<leader>AA', function() require('opencode').ask('@file ') end, desc = 'Ask opencode about current file', mode = { 'n', 'v' }, },
      { '<leader>An', function() require('opencode').command('/new') end, desc = 'New session', },
      { '<leader>Ae', function() require('opencode').prompt('Explain @cursor and its context') end, desc = 'Explain code near cursor' },
      { '<leader>Ar', function() require('opencode').prompt('Review @file for correctness and readability') end, desc = 'Review file', },
      { '<leader>Af', function() require('opencode').prompt('Fix these @diagnostics') end, desc = 'Fix errors', },
      { '<leader>Ao', function() require('opencode').prompt('Optimize @selection for performance and readability') end, desc = 'Optimize selection', mode = 'v', },
      { '<leader>Ad', function() require('opencode').prompt('Add documentation comments for @selection') end, desc = 'Document selection', mode = 'v', },
      { '<leader>At', function() require('opencode').prompt('Add tests for @selection') end, desc = 'Test selection', mode = 'v', },
    },
  },
  -- {
  --   "folke/sidekick.nvim",
  --   opts = {
  --     -- add any options here
  --     cli = {
  --       mux = {
  --         backend = "zellij",
  --         enabled = true,
  --       },
  --     },
  --   },
  --   keys = {
  --     {
  --       "<tab>",
  --       function()
  --         -- if there is a next edit, jump to it, otherwise apply it if any
  --         if not require("sidekick").nes_jump_or_apply() then
  --           return "<Tab>" -- fallback to normal tab
  --         end
  --       end,
  --       expr = true,
  --       desc = "Goto/Apply Next Edit Suggestion",
  --     },
  --     {
  --       "<c-.>",
  --       function()
  --         require("sidekick.cli").focus()
  --       end,
  --       mode = { "n", "x", "i", "t" },
  --       desc = "Sidekick Switch Focus",
  --     },
  --     {
  --       -- doesn't work when binding from avante config, so doing it here
  --       "<leader>aa",
  --       function()
  --         require("avante").toggle()
  --       end,
  --       desc = "avante: toggle",
  --     },
  --     {
  --       "<leader>aA",
  --       function()
  --         require("sidekick.cli").toggle({ focus = true })
  --       end,
  --       desc = "Sidekick Toggle CLI",
  --       mode = { "n", "v" },
  --     },
  --     -- {
  --     --   "<leader>ac",
  --     --   function()
  --     --     require("sidekick.cli").toggle({ name = "claude", focus = true })
  --     --   end,
  --     --   desc = "Sidekick Claude Toggle",
  --     --   mode = { "n", "v" },
  --     -- },
  --     -- {
  --     --   "<leader>ag",
  --     --   function()
  --     --     require("sidekick.cli").toggle({ name = "grok", focus = true })
  --     --   end,
  --     --   desc = "Sidekick Grok Toggle",
  --     --   mode = { "n", "v" },
  --     -- },
  --     {
  --       "<leader>ap",
  --       function()
  --         require("sidekick.cli").prompt()
  --       end,
  --       desc = "Sidekick Ask Prompt",
  --       mode = { "n", "v" },
  --     },
  --   },
  -- },
}
