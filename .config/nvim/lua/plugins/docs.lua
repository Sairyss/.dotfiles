return {
  {
    "emmanueltouzery/apidocs.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "folke/snacks.nvim",
      -- "nvim-telescope/telescope.nvim", -- or, 'folke/snacks.nvim'
    },
    cmd = { "ApidocsSearch", "ApidocsInstall", "ApidocsOpen", "ApidocsSelect", "ApidocsUninstall" },
    config = function()
      local apidocs = require("apidocs")
      apidocs.setup({ picker = "snacks" })
      apidocs.ensure_install({ "javascript", "typescript", "node", "man", "docker", "git" })
      -- Picker will be auto-detected. To select a picker of your choice explicitly you can set picker by the configuration option 'picker':
      -- require('apidocs').setup({picker = "snacks"})
      -- Possible options are 'ui_select', 'telescope', and 'snacks'
      -- You can change the keymap for following "local://" links by setting the configuration option 'follow_link_keymap' (default is "<C-]>"):
      -- require('apidocs').setup({follow_link_keymap = "<C-]>"})
    end,
    keys = {
      { "<leader>sA", "<cmd>ApidocsOpen<cr>", desc = "Search Api Doc" },
    },
  },
  {
    "amrbashir/nvim-docs-view",
    lazy = true,
    cmd = "DocsViewToggle",
    opts = {
      position = "right",
      width = 60,
      update_mode = "manual",
    },
    keys = {
      { "<leader>cK", "<cmd>DocsViewToggle<cr><cmd>DocsViewUpdate<cr>", desc = "LSP Docs Preview" },
    },
  },
}
