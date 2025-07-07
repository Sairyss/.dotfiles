-- Tab management plugins
return {
  {
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
        "<leader>1",
        mode = { "n" },
        "1gt",
        desc = "Tab 1",
      },
      {
        "<leader>2",
        mode = { "n" },
        "2gt",
        desc = "Tab 2",
      },
      {
        "<leader>3",
        mode = { "n" },
        "3gt",
        desc = "Tab 3",
      },
      {
        "<leader>4",
        mode = { "n" },
        "4gt",
        desc = "Tab 4",
      },
      {
        "<leader>5",
        mode = { "n" },
        "5gt",
        desc = "Tab 5",
      },
    },
  },
}
