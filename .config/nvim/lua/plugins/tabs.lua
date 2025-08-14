-- Tab management plugins
return {
  {
    -- make buffers scoped per tab
    "tiagovla/scope.nvim",
    config = function()
      require("scope").setup({
        hooks = {
          pre_tab_enter = function()
            -- Your custom logic to run before entering a tab
          end,
        },
      })
    end,
  },
  {
    "nanozuki/tabby.nvim",
    ---@type TabbyConfig
    opts = {
      -- configs...
    },
    keys = {
      {
        "<leader><tab>1",
        mode = { "n" },
        ":tabnext 1<cr>",
        desc = "Switch to Tab 1",
        silent = true,
      },
      {
        "<leader><tab>2",
        mode = { "n" },
        ":tabnext 2<cr>",
        desc = "Switch to Tab 2",
        silent = true,
      },
      {
        "<leader><tab>3",
        mode = { "n" },
        ":tabnext 3<cr>",
        desc = "Switch to Tab 3",
        silent = true,
      },
      {
        "<leader><tab>4",
        mode = { "n" },
        ":tabnext 4<cr>",
        desc = "Switch to Tab 4",
        silent = true,
      },
      {
        "<leader><tab>5",
        mode = { "n" },
        ":tabnext 5<cr>",
        desc = "Switch to Tab 5",
        silent = true,
      },
    },
  },
}
