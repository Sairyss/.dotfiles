return {
  { "ChmaraX/herdr-nvim", opts = {} },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      -- custom <M-h/l> navigation between nvim splits (incl. neo-tree / terminal) and herdr panes;
      -- calls ~/.dotfiles/.config/herdr/local-plugins/vim-herdr-navigation/navigate.sh at a split edge
      require("plugins.herdr.navigation")
    end,
  },
}
