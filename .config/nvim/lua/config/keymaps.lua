-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap = vim.api.nvim_set_keymap

-- do not copy a single letter to the 0 register when using 'x'
keymap("n", "x", '"_x', { desc = "Deleting with X doesn't copy deleted character", noremap = true, silent = true })

-- Swap go to mark
keymap("n", "'", "`", { desc = "Go to mark", noremap = true, silent = true })
keymap("n", "`", "'", { desc = "Go to mark", noremap = true, silent = true })

-- map ] and [ for ; and , (easier to reach on my keyboard)
keymap("n", ";", "]", { desc = "+next", noremap = false, silent = true })
keymap("n", ",", "[", { desc = "+prev", noremap = false, silent = true })

-- easier shortcuts for going to the end/beginning of the line
keymap("n", "<M-f>", "$", { desc = "Go to the end of line", noremap = false, silent = true })
keymap("n", "<M-d>", "^", { desc = "Go to the beginning of line", noremap = false, silent = true })

-- Center screen when navigating
keymap("n", "<C-d>", "<C-d>zz", { desc = "Center screen when moving down", noremap = true, silent = true })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Center screen when moving up", noremap = true, silent = true })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
keymap("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
keymap("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
keymap("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
keymap("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
keymap("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
keymap("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

---------- Extensions ----------

if not vim.g.vscode then
  keymap("n", "<F2>", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "Rename", noremap = true, silent = true })
end
