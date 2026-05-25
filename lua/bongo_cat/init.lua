local animator = require("bongo_cat.animator")
local config = require("bongo_cat.config")
local frames = require("bongo_cat.frames")
local pomodoro = require("bongo_cat.pomodoro")
local events = require("bongo_cat.events")
local window = require("bongo_cat.window")

local M = {
  state = {
    setup = false,
    keymaps = {},
  },
}

local function set_keymap(key, callback, desc)
  if not key then
    return
  end

  vim.keymap.set("n", key, callback, { desc = desc, silent = true })
  table.insert(M.state.keymaps, key)
end

local function ensure_setup()
  if not M.state.setup then
    M.setup()
  end
end

function M.setup(opts)
  if M.state.setup then
    return
  end

  math.randomseed(os.time())
  config.setup(opts)
  events.setup()

  set_keymap(config.get("keymaps.toggle"), function()
    M.toggle()
  end, "Toggle Bongo Cat")

  set_keymap(config.get("keymaps.pomodoro_start"), function()
    M.pomodoro("start")
  end, "Start Bongodoro Pomodoro")

  set_keymap(config.get("keymaps.pomodoro_pause_resume"), function()
    M.pomodoro("pause_resume")
  end, "Pause or resume Bongodoro Pomodoro")

  set_keymap(config.get("keymaps.pomodoro_stop"), function()
    M.pomodoro("stop")
  end, "Stop Bongodoro Pomodoro")

  set_keymap(config.get("keymaps.pomodoro_status"), function()
    M.pomodoro("status")
  end, "Show Bongodoro Pomodoro status")

  if config.get("auto_start") then
    vim.schedule(function()
      M.show()
    end)
  end

  M.state.setup = true
end

function M.show()
  ensure_setup()

  if window.is_visible() then
    return
  end

  if not window.open() then
    return
  end

  window.render(frames.get("idle"))
  animator.start(window.render)
end

function M.hide()
  if not M.state.setup or not window.is_visible() then
    return
  end

  animator.stop()
  window.close()
end

function M.toggle()
  if window.is_visible() then
    M.hide()
  else
    M.show()
  end
end

function M.is_visible()
  return window.is_visible()
end

function M.status()
  return {
    setup = M.state.setup,
    visible = window.is_visible(),
    pomodoro = pomodoro.status(),
  }
end

function M.pomodoro(command)
  ensure_setup()

  if command == "start" then
    return pomodoro.start("work")
  elseif command == "pause" then
    return pomodoro.pause()
  elseif command == "pause_resume" then
    if pomodoro.status().mode == "paused" then
      return pomodoro.resume()
    end
    return pomodoro.pause()
  elseif command == "resume" then
    return pomodoro.resume()
  elseif command == "stop" then
    return pomodoro.stop()
  elseif command == "status" or not command then
    return pomodoro.status()
  end

  return nil, "Unknown pomodoro command: " .. tostring(command)
end

function M.cleanup()
  animator.destroy()
  pomodoro.cleanup()
  events.cleanup()
  window.close()
  for _, key in ipairs(M.state.keymaps) do
    pcall(vim.keymap.del, "n", key)
  end
  M.state.keymaps = {}
  M.state.setup = false
end

return M
