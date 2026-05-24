if vim.g.loaded_bongo_cat then
  return
end

vim.g.loaded_bongo_cat = true

vim.api.nvim_create_user_command("BongoCat", function(opts)
  local bongo = require("bongo_cat")
  local arg = opts.args

  bongo.setup()

  if arg == "" or arg == "toggle" then
    bongo.toggle()
  elseif arg == "show" then
    bongo.show()
  elseif arg == "hide" then
    bongo.hide()
  elseif arg == "status" then
    local status = bongo.status()
    vim.notify(
      string.format("Bongo Cat setup=%s visible=%s", tostring(status.setup), tostring(status.visible)),
      vim.log.levels.INFO
    )
  else
    vim.notify("Unknown BongoCat subcommand: " .. arg, vim.log.levels.WARN)
  end
end, {
  nargs = "?",
  complete = function()
    return { "toggle", "show", "hide", "status" }
  end,
})
