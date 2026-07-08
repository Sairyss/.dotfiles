return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      transparent = false,
      styles = {
        sidebars = "dark",
        floats = "dark",
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
        -- Snacks picker: NvChad-style borderless with theme accent colors
        -- local bg = "#1e2030"
        -- local cyan = "#04d1f9"
        -- local green = colors.green
        -- hl.SnacksPickerBorder = { fg = bg, bg = bg }
        -- hl.SnacksPicker = { bg = bg }
        -- hl.SnacksPickerPreviewBorder = { fg = bg, bg = bg }
        -- hl.SnacksPickerPreview = { bg = bg }
        -- hl.SnacksPickerPreviewTitle = { fg = bg, bg = cyan }
        -- hl.SnacksPickerBoxBorder = { fg = bg, bg = bg }
        -- hl.SnacksPickerInputBorder = { fg = bg, bg = bg }
        -- hl.SnacksPickerInputSearch = { fg = cyan, bg = bg }
        -- hl.SnacksPickerListBorder = { fg = bg, bg = bg }
        -- hl.SnacksPickerList = { bg = bg }
        -- hl.SnacksPickerListTitle = { fg = bg, bg = green }
      end,
    },
  },
}
