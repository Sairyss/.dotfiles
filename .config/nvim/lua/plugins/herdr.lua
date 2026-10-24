local in_herdr = (vim.env.HERDR_PANE_ID or "") ~= ""

return {
  { "ChmaraX/herdr-nvim", cond = in_herdr, opts = {} },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      -- custom <M-h/j/k/l> navigation between nvim splits (incl. neo-tree / terminal); always loaded,
      -- at a split edge it crosses into herdr (if in herdr) or tmux (TmuxNavigate*, from this plugin);
      -- in herdr it calls ~/.dotfiles/.config/herdr/local-plugins/vim-herdr-navigation/navigate.sh at a split edge
      require("plugins.herdr.navigation")
    end,
  },
}
