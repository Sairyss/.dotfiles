-- Code navigation plugins
return {
  {
    "chrisgrieser/nvim-spider",
    lazy = true,
    keys = {
      {
        "<M-w>",
        "<cmd>lua require('spider').motion('w', { skipInsignificantPunctuation = true, subwordMovement = false, })<CR>",
        mode = { "n", "o", "x" },
      },
      {
        "<M-e>",
        "<cmd>lua require('spider').motion('e', { skipInsignificantPunctuation = true, subwordMovement = false, })<CR>",
        mode = { "n", "o", "x" },
      },
      {
        "<M-b>",
        "<cmd>lua require('spider').motion('b', { skipInsignificantPunctuation = true, subwordMovement = false, })<CR>",
        mode = { "n", "o", "x" },
      },

      {
        "w",
        "<cmd>lua require('spider').motion('w', { skipInsignificantPunctuation = false, })<CR>",
        mode = { "n", "o", "x" },
      },
      {
        "e",
        "<cmd>lua require('spider').motion('e', { skipInsignificantPunctuation = false, })<CR>",
        mode = { "n", "o", "x" },
      },
      {
        "b",
        "<cmd>lua require('spider').motion('b', { skipInsignificantPunctuation = false, })<CR>",
        mode = { "n", "o", "x" },
      },
    },
  },
  {
    "aaronik/treewalker.nvim",
    opts = {
      highlight = true, -- default is false
    },
    keys = {
      { "<M-h>", ":Treewalker Left<CR>zz", silent = true, mode = { "n" } },
      { "<M-j>", ":Treewalker Down<CR>zz", silent = true, mode = { "n" } },
      { "<M-k>", ":Treewalker Up<CR>zz", silent = true, mode = { "n" } },
      { "<M-l>", ":Treewalker Right<CR>zz", silent = true, mode = { "n" } },
      { "<C-S-j>", "<cmd>Treewalker SwapDown<cr>", silent = true, mode = { "n" } },
      { "<C-S-k>", "<cmd>Treewalker SwapUp<cr>", silent = true, mode = { "n" } },
    },
  },
}
