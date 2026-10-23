return {
  { "ChmaraX/herdr-nvim", opts = {} },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      require("herdr_navigation")
    end,
  },
}
