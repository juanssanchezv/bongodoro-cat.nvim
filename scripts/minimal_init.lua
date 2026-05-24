vim.opt.runtimepath:append(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h"))

require("bongo_cat").setup({
  auto_start = true,
  window = {
    position = "bottom-right",
    border = "rounded",
  },
  input = {
    enabled_mode_prefixes = { "i", "R", "c", "r" },
    count_backspace = true,
    count_enter = true,
    count_tab = true,
    count_space = true,
  },
})

vim.keymap.set("n", "<leader>bt", function()
  require("bongo_cat").toggle()
end, { desc = "Toggle Bongo Cat (dev)" })

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.notify("Bongo Cat dev mode loaded. Type in Insert mode to test.", vim.log.levels.INFO)
  end,
})
