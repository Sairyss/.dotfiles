return {
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup(--[[optional config]])
    end,
  },
  {
    "MattiasMTS/cmp-dbee",
    branch = "ms/v2",
    dependencies = {
      { "kndndrj/nvim-dbee" },
    },
    ft = "sql", -- optional but good to have
    opts = {}, -- needed
  },
  {
    "saghen/blink.compat",
    -- use v2.* for blink.cmp v1.*
    version = "2.*",
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        compat = { "dbee" },
        providers = {
          dbee = { name = "dbee", module = "blink.compat.source" },
        },
      },
    },
  },
}
