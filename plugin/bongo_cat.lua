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
      string.format(
        "Bongo Cat setup=%s visible=%s pomodoro=%s %s",
        tostring(status.setup),
        tostring(status.visible),
        status.pomodoro.mode,
        status.pomodoro.remaining
      ),
      vim.log.levels.INFO
    )
  elseif vim.startswith(arg, "pomodoro") then
    local parts = vim.split(arg, "%s+", { trimempty = true })
    local result, err = bongo.pomodoro(parts[2] or "status")
    if err then
      vim.notify(err, vim.log.levels.WARN)
    elseif parts[2] == "status" or not parts[2] then
      vim.notify(
        string.format("Pomodoro %s %s", result.mode, result.remaining),
        vim.log.levels.INFO
      )
    else
      local status = bongo.pomodoro("status")
      vim.notify(
        string.format("Pomodoro %s %s", status.mode, status.remaining),
        vim.log.levels.INFO
      )
    end
  else
    vim.notify("Unknown BongoCat subcommand: " .. arg, vim.log.levels.WARN)
  end
end, {
  nargs = "*",
  complete = function(_, line)
    if line:match("^%s*BongoCat%s+pomodoro%s+") then
      return { "start", "pause", "pause_resume", "resume", "stop", "status" }
    end
    return { "toggle", "show", "hide", "status", "pomodoro" }
  end,
})
