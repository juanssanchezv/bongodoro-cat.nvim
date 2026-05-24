local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:append(root)

local function assert_true(value, message)
  if not value then
    error(message or "assertion failed", 2)
  end
end

local config = require("bongo_cat.config")
local frames = require("bongo_cat.frames")
local animator = require("bongo_cat.animator")
local events = require("bongo_cat.events")
local window = require("bongo_cat.window")
local bongo = require("bongo_cat")

config.setup({
  auto_start = false,
  animation = {
    idle_delay_min = 1,
    idle_delay_max = 1,
    idle_min_cycles = 2,
    idle_max_cycles = 2,
    idle_frame_tick = 10,
    sleep_timeout = 30,
    sleep_tick = 10,
    event_tick = 10,
  },
  events = {
    error = true,
  },
})

local width, height = frames.dimensions()
assert_true(width > 0, "expected positive frame width")
assert_true(height > 0, "expected positive frame height")

for _, name in ipairs(frames.order) do
  assert_true(#frames.get(name) == height, name .. " frame height mismatch")
end

local rendered = {}
animator.start(function(frame)
  table.insert(rendered, frame)
end)

assert_true(#rendered >= 1, "animator did not render initial frame")

animator.on_input()
animator.on_input()
assert_true(#rendered >= 3, "input did not render left/right frames")

local saw_save = false
animator.on_event("save")
vim.wait(120, function()
  for _, frame in ipairs(rendered) do
    if frame == frames.save then
      saw_save = true
      return true
    end
  end
end)
assert_true(saw_save, "save event did not render save frame")
vim.wait(250, function()
  return animator.state.sequence == nil
end)
assert_true(animator.state.sequence == nil, "save sequence did not finish")

local saw_error = false
animator.on_event("error")
vim.wait(120, function()
  for _, frame in ipairs(rendered) do
    if frame == frames.error then
      saw_error = true
      return true
    end
  end
end)
assert_true(saw_error, "error event did not render error frame")

vim.wait(160, function()
  return animator.state.current == "sleep_a" or animator.state.current == "sleep_b"
end)
assert_true(animator.state.current == "sleep_a" or animator.state.current == "sleep_b", "sleep did not start")

animator.on_input()
assert_true(animator.state.current == "left" or animator.state.current == "right", "input did not wake from sleep")
animator.destroy()

events.setup()
local error_events = 0
local original_on_event = animator.on_event
local original_is_visible = window.is_visible
window.is_visible = function()
  return true
end
animator.on_event = function(name)
  if name == "error" then
    error_events = error_events + 1
  end
end

local buf = vim.api.nvim_create_buf(false, true)
vim.diagnostic.set(vim.api.nvim_create_namespace("bongodoro-smoke"), buf, {
  {
    lnum = 0,
    col = 0,
    message = "smoke error",
    severity = vim.diagnostic.severity.ERROR,
  },
})
vim.wait(120, function()
  return error_events == 1
end)
assert_true(error_events == 1, "diagnostic error did not trigger once")

vim.diagnostic.set(vim.api.nvim_create_namespace("bongodoro-smoke"), buf, {
  {
    lnum = 0,
    col = 1,
    message = "same smoke error",
    severity = vim.diagnostic.severity.ERROR,
  },
})
vim.wait(50)
assert_true(error_events == 1, "diagnostic error retriggered while errors persisted")

vim.diagnostic.reset(vim.api.nvim_create_namespace("bongodoro-smoke"), buf)
vim.wait(50)
vim.diagnostic.set(vim.api.nvim_create_namespace("bongodoro-smoke"), buf, {
  {
    lnum = 0,
    col = 2,
    message = "new smoke error",
    severity = vim.diagnostic.severity.ERROR,
  },
})
vim.wait(120, function()
  return error_events == 2
end)
assert_true(error_events == 2, "diagnostic error did not retrigger after clearing")
vim.api.nvim_buf_delete(buf, { force = true })
animator.on_event = original_on_event
window.is_visible = original_is_visible
events.cleanup()

bongo.setup({ auto_start = false })
local status = bongo.status()
assert_true(status.setup == true, "plugin setup status is false")
bongo.cleanup()

print(string.format("bongodoro-cat.nvim smoke ok: frames=%dx%d", width, height))
