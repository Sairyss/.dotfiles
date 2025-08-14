return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      transparent = false,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      style = "moon",
      on_colors = function(colors)
        colors.bg = "#1e2030"
        colors.border_highlight = "#04d1f9"
      end,
      on_highlights = function(hl, colors)
        -- Telescope
        hl.TelescopeBorder = {
          bg = "#1e2030",
          fg = "#04d1f9",
        }
        hl.TelescopePromptBorder = {
          bg = "#1e2030",
          fg = "#04d1f9",
        }
        hl.TelescopePromptTitle = {
          bg = "#1e2030",
          fg = "#04d1f9",
        }
      end,
    },
  },
}
