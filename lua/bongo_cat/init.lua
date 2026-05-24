local animator = require("bongo_cat.animator")
local config = require("bongo_cat.config")
local frames = require("bongo_cat.frames")
local events = require("bongo_cat.events")
local window = require("bongo_cat.window")

local M = {
  state = {
    setup = false,
  },
}

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

  local keymap = config.get("keymaps.toggle")
  if keymap then
    vim.keymap.set("n", keymap, function()
      M.toggle()
    end, { desc = "Toggle Bongo Cat", silent = true })
  end

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
  }
end

function M.cleanup()
  animator.destroy()
  events.cleanup()
  window.close()
  M.state.setup = false
end

return M
