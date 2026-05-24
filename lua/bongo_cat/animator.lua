local config = require("bongo_cat.config")
local frames = require("bongo_cat.frames")
local pomodoro = require("bongo_cat.pomodoro")

local uv = vim.uv or vim.loop

local M = {
  state = {
    timer = nil,
    render = nil,
    running = false,
    sequence = nil,
    index = 0,
    current = "right",
    pending_hit = nil,
    last_side = "right",
    last_input_at = 0,
    pending_event = nil,
    sleeping = false,
    sleep_flip = false,
  },
}

local function now_ms()
  return math.floor(uv.hrtime() / 1000000)
end

local function random_idle_delay()
  local min = config.get("animation.idle_delay_min")
  local max = config.get("animation.idle_delay_max")
  return math.random(min, max)
end

local function random_idle_cycles()
  local min = config.get("animation.idle_min_cycles")
  local max = config.get("animation.idle_max_cycles")
  return math.random(min, max)
end

local function current_side_frame()
  return M.state.last_side == "left" and "left" or "right"
end

local function should_sleep()
  return now_ms() - M.state.last_input_at >= config.get("animation.sleep_timeout")
end

local function ensure_timer()
  if not M.state.timer then
    M.state.timer = uv.new_timer()
  end
end

local function stop_timer()
  if M.state.timer then
    M.state.timer:stop()
  end
end

local function render(name)
  M.state.current = name
  if name == "left" or name == "right" then
    M.state.last_side = name
  end
  if M.state.render then
    M.state.render(pomodoro.decorate(frames.get(name)))
  end
end

local schedule

local function sleep_frame()
  M.state.sleep_flip = not M.state.sleep_flip
  return M.state.sleep_flip and "sleep_a" or "sleep_b"
end

local function enter_sleep()
  M.state.sequence = nil
  M.state.index = 0
  M.state.sleeping = true
  render(sleep_frame())
  schedule(config.get("animation.sleep_tick"), enter_sleep)
end

function schedule(delay, cb)
  ensure_timer()
  stop_timer()
  M.state.timer:start(delay, 0, function()
    vim.schedule(cb)
  end)
end

local function start_idle_loop()
  if not M.state.running then
    return
  end

  if should_sleep() then
    enter_sleep()
    return
  end

  local sequence = {}
  for _ = 1, random_idle_cycles() do
    table.insert(sequence, { name = "left", duration = config.get("animation.idle_frame_tick"), interruptible = true })
    table.insert(sequence, { name = "right", duration = config.get("animation.idle_frame_tick"), interruptible = true })
  end

  M.play_sequence(sequence, function()
    if should_sleep() then
      enter_sleep()
      return
    end

    schedule(random_idle_delay(), start_idle_loop)
  end)
end

function M.play_sequence(sequence, on_complete)
  M.state.sequence = sequence
  M.state.index = 1

  local function step()
    if not M.state.running or not M.state.sequence then
      return
    end

    local item = M.state.sequence[M.state.index]
    if not item then
      M.state.sequence = nil
      M.state.index = 0

      if M.state.pending_event then
        local next_event = M.state.pending_event
        M.state.pending_event = nil
        M.trigger_event(next_event)
        return
      end

      if M.state.pending_hit then
        local next_hit = M.state.pending_hit
        M.state.pending_hit = nil
        M.trigger_hit(next_hit)
        return
      end

      if on_complete then
        on_complete()
      end
      return
    end

    render(item.name)
    M.state.index = M.state.index + 1
    schedule(item.duration, step)
  end

  step()
end

function M.trigger_event(name)
  local events = {
    save = {
      { name = "save", duration = config.get("animation.event_tick"), interruptible = false },
      { name = current_side_frame(), duration = 120, interruptible = true },
    },
    error = {
      { name = "error", duration = config.get("animation.event_tick"), interruptible = false },
      { name = current_side_frame(), duration = 120, interruptible = true },
    },
  }

  local sequence = events[name]
  if not sequence then
    return
  end

  M.play_sequence(sequence, function()
    if should_sleep() then
      enter_sleep()
      return
    end

    schedule(random_idle_delay(), start_idle_loop)
  end)
end

function M.trigger_hit(kind)
  M.state.last_side = kind == "left" and "left" or "right"
  render(current_side_frame())
  schedule(random_idle_delay(), start_idle_loop)
end

function M.start(render_fn)
  M.state.render = render_fn
  M.state.running = true
  M.state.sequence = nil
  M.state.pending_hit = nil
  M.state.pending_event = nil
  M.state.last_input_at = now_ms()
  M.state.sleeping = false
  pomodoro.set_redraw(function()
    if M.state.running and M.state.current then
      render(M.state.current)
    end
  end)
  render(current_side_frame())
  schedule(random_idle_delay(), start_idle_loop)
end

function M.stop()
  M.state.running = false
  M.state.sequence = nil
  M.state.pending_hit = nil
  M.state.pending_event = nil
  M.state.sleeping = false
  pomodoro.set_redraw(nil)
  stop_timer()
end

function M.on_input()
  if not M.state.running then
    return
  end

  local now = now_ms()
  M.state.last_input_at = now
  M.state.sleeping = false

  local kind
  kind = M.state.last_side == "left" and "right" or "left"

  if M.state.sequence then
    local current_item = M.state.sequence[math.max(M.state.index - 1, 1)]
    if current_item and current_item.interruptible then
      M.state.sequence = nil
      stop_timer()
      M.trigger_hit(kind)
      return
    end

    M.state.pending_hit = kind
    return
  end

  stop_timer()
  M.trigger_hit(kind)
end

function M.on_event(name)
  if not M.state.running then
    return
  end

  if M.state.sequence then
    local current_item = M.state.sequence[math.max(M.state.index - 1, 1)]
    if current_item and current_item.interruptible then
      M.state.sequence = nil
      stop_timer()
      M.trigger_event(name)
      return
    end

    M.state.pending_event = name
    return
  end

  stop_timer()
  M.trigger_event(name)
end

function M.destroy()
  M.stop()
  if M.state.timer then
    M.state.timer:close()
    M.state.timer = nil
  end
end

return M
