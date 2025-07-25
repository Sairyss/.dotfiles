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
  },
}
