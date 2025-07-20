-- Code automation like snippets, hotkeys, toggling, etc.

return {
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!).
    build = "make install_jsregexp",
    opts = {
      -- update_events = "TextChanged,TextChangedI",
      -- enable_autosnippets = true,
      history = true,
    },
    -- config = function(_, opts)
    --   local luasnip = require("luasnip")
    --   luasnip.setup(opts)
    --   require("luasnip.loaders.from_lua").load({ paths = { "~/.config/nvim/lua/config/snippets" } })
    -- end,
    keys = {
      {
        "<C-l>",
        function()
          local luasnip = require("luasnip")
          if luasnip.jumpable(1) then
            luasnip.jump(1)
          else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-l>", true, false, true), "n", true)
          end
        end,
        mode = { "i", "s" },
        silent = true,
      },
      {
        "<C-h>",
        function()
          local luasnip = require("luasnip")
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-h>", true, false, true), "n", true)
          end
        end,
        mode = { "i", "s" },
        silent = true,
      },
      {
        mode = { "i", "s" },
        "<C-j>",
        "<Plug>luasnip-next-choice",
        function()
          local luasnip = require("luasnip")
          if luasnip.choice_active() then
            luasnip.change_choice(1)
          else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-j>", true, false, true), "n", true)
          end
        end,
        desc = "Jump to the next choice in a snippet",
        silent = true,
      },
      {
        mode = { "i", "s" },
        "<C-k>",
        function()
          local luasnip = require("luasnip")
          if luasnip.choice_active() then
            luasnip.change_choice(-1)
          else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-k>", true, false, true), "n", true)
          end
        end,
        desc = "Jump to the next choice in a snippet",
        silent = true,
      },
    },
  },

  {
    -- ctrl + a/x to increment/decrement or cycle through values
    "monaqa/dial.nvim",
    desc = "Increment and decrement numbers, dates, and more",
    -- keys = {
    --   { "<C-a>", function() return M.dial(true) end, expr = true, desc = "Increment", mode = {"n", "v"} },
    --   { "<C-x>", function() return M.dial(false) end, expr = true, desc = "Decrement", mode = {"n", "v"} },
    --   { "g<C-a>", function() return M.dial(true, true) end, expr = true, desc = "Increment", mode = {"n", "v"} },
    --   { "g<C-x>", function() return M.dial(false, true) end, expr = true, desc = "Decrement", mode = {"n", "v"} },
    -- },
    opts = function()
      local augend = require("dial.augend")

      local logical_alias = augend.constant.new({
        elements = { "&&", "||" },
        word = false,
        cyclic = true,
      })

      local ordinal_numbers = augend.constant.new({
        -- elements through which we cycle. When we increment, we go down
        -- On decrement we go up
        elements = {
          "first",
          "second",
          "third",
          "fourth",
          "fifth",
          "sixth",
          "seventh",
          "eighth",
          "ninth",
          "tenth",
        },
        -- if true, it only matches strings with word boundary. firstDate wouldn't work for example
        word = false,
        -- do we cycle back and forth (tenth to first on increment, first to tenth on decrement).
        -- Otherwise nothing will happen when there are no further values
        cyclic = true,
      })

      local weekdays = augend.constant.new({
        elements = {
          "Monday",
          "Tuesday",
          "Wednesday",
          "Thursday",
          "Friday",
          "Saturday",
          "Sunday",
        },
        word = true,
        cyclic = true,
      })

      local months = augend.constant.new({
        elements = {
          "January",
          "February",
          "March",
          "April",
          "May",
          "June",
          "July",
          "August",
          "September",
          "October",
          "November",
          "December",
        },
        word = true,
        cyclic = true,
      })

      local capitalized_boolean = augend.constant.new({
        elements = {
          "True",
          "False",
        },
        word = true,
        cyclic = true,
      })

      return {
        dials_by_ft = {
          css = "css",
          vue = "vue",
          javascript = "typescript",
          typescript = "typescript",
          typescriptreact = "typescript",
          javascriptreact = "typescript",
          json = "json",
          lua = "lua",
          markdown = "markdown",
          sass = "css",
          scss = "css",
          python = "python",
        },
        groups = {
          default = {
            augend.integer.alias.decimal, -- nonnegative decimal number (0, 1, 2, 3, ...)
            augend.integer.alias.decimal_int, -- nonnegative and negative decimal number
            augend.integer.alias.hex, -- nonnegative hex number  (0x01, 0x1a1f, etc.)
            augend.date.alias["%Y/%m/%d"], -- date (2022/02/19, etc.)
            ordinal_numbers,
            weekdays,
            months,
            capitalized_boolean,
            augend.constant.alias.bool, -- boolean value (true <-> false)
            logical_alias,
          },
          vue = {
            augend.constant.new({ elements = { "let", "const" } }),
            augend.hexcolor.new({ case = "lower" }),
            augend.hexcolor.new({ case = "upper" }),
          },
          typescript = {
            augend.constant.new({ elements = { "let", "const" } }),

            -- added custom
            augend.constant.new({ elements = { "private", "public", "protected" } }),
            augend.constant.new({ elements = { "class", "export class", "export abstract class" } }),
            augend.constant.new({
              elements = { "() =>", "async () =>" },
              word = false,
              cyclic = true,
            }),
            augend.constant.new({
              elements = { "(i) =>", "async (i) =>" },
              word = false,
              cyclic = true,
            }),
            augend.constant.new({
              elements = { "function", "export function", "async function", "export async function" },
            }),
            augend.constant.new({
              elements = { "any", "unknown", "void" },
              word = false,
              cyclic = true,
            }),
            augend.constant.new({ elements = { "===", "!==" }, word = false, cyclic = true }),
            augend.constant.new({ elements = { "==", "!=" }, word = false, cyclic = true }),
            augend.constant.new({
              elements = { ".", "?." },
              word = false,
              cyclic = true,
              pattern_regexp = [[\v(\k)@<=\.|\?\.]], -- Matches '.' or '?.' following a word
            }),
            -- augend.constant.new({
            --   elements = { ":", "?:" },
            --   word = false,
            --   cyclic = true,
            --   pattern_regexp = [[\v(\k)@<=:|\?:]], -- Matches ':' or '?:' following a word
            -- }),
            -- script below toggles surrounding quotes, but breaks toggling of other things inside the quotes
            -- augend.paren.new({
            --   patterns = { { "'", "'" }, { '"', '"' }, { "`", "`" } },
            --   nested = true,
            --   cyclic = true,
            -- }),
          },
          css = {
            augend.hexcolor.new({
              case = "lower",
            }),
            augend.hexcolor.new({
              case = "upper",
            }),
          },
          markdown = {
            augend.constant.new({
              elements = { "[ ]", "[x]" },
              word = false,
              cyclic = true,
            }),
            augend.misc.alias.markdown_header,
          },
          json = {
            augend.semver.alias.semver, -- versioning (v1.1.2)
          },
          lua = {
            augend.constant.new({
              elements = { "and", "or" },
              word = true, -- if false, "sand" is incremented into "sor", "doctor" into "doctand", etc.
              cyclic = true, -- "or" is incremented into "and".
            }),
          },
          python = {
            augend.constant.new({ elements = { "and", "or" } }),

            -- added custom
            augend.constant.new({ elements = { "==", "!=" }, word = false, cyclic = true }),
          },
        },
      }
    end,
    config = function(_, opts)
      -- copy defaults to each group
      for name, group in pairs(opts.groups) do
        if name ~= "default" then
          vim.list_extend(group, opts.groups.default)
        end
      end
      require("dial.config").augends:register_group(opts.groups)
      vim.g.dials_by_ft = opts.dials_by_ft
    end,
  },
  {
    -- insert print/log statements with hotkeys
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("timber").setup({
        log_templates = {
          default = {
            lua = [[print("LOG %log_target ON LINE %line_number", %log_target)]],
            javascript = [[console.log("[Line %line_number]: %log_target", %log_target)]],
            typescript = [[console.log("[Line %line_number]: %log_target", %log_target)]],
          },
        },
      })
    end,
    keys = {
      {
        mode = { "n", "x" },
        "<C-M-l>",
        function()
          return require("timber.actions").insert_log({ position = "below" })
        end,
      },
      {
        "n",
        "gll",
        function()
          return require("timber.actions").insert_log({ position = "below", operator = true }) .. "_"
        end,
        desc = "Insert log statements for the current line",
        expr = true,
      },
      {
        "n",
        "gls",
        function()
          require("timber.actions").insert_log({
            templates = { before = "default", after = "default" },
            position = "surround",
          })
        end,
        desc = "Insert surround log statements below",
      },
    },
  },
  {
    -- plugin for splitting/joining blocks of code like arrays, hashes, statements, objects, dictionaries, etc.
    "Wansmer/treesj",
    keys = {
      {
        "<M-t>",
        function()
          local t = require("treesj")
          t.toggle()
        end,
      },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" }, -- if you install parsers with `nvim-treesitter`
    config = function()
      require("treesj").setup({
        use_default_keymaps = false,
      })
    end,
  },
}
