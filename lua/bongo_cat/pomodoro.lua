local config = require("bongo_cat.config")

local uv = vim.uv or vim.loop

local M = {
  state = {
    timer = nil,
    mode = "stopped",
    previous_mode = nil,
    remaining_ms = 0,
    ends_at = 0,
    completed_sessions = 0,
    redraw = nil,
  },
}

local function now_ms()
  return math.floor(uv.hrtime() / 1000000)
end

local function minutes_to_ms(minutes)
  return (minutes or 0) * 60 * 1000
end

local function duration_for(mode)
  if mode == "short_break" then
    return minutes_to_ms(config.get("pomodoro.short_break_minutes"))
  end

  if mode == "long_break" then
    return minutes_to_ms(config.get("pomodoro.long_break_minutes"))
  end

  return minutes_to_ms(config.get("pomodoro.work_minutes"))
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

local function schedule_tick()
  ensure_timer()
  stop_timer()
  M.state.timer:start(1000, 1000, function()
    vim.schedule(function()
      M.tick()
    end)
  end)
end

local function redraw()
  if M.state.redraw then
    M.state.redraw()
  end
end

local function format_time(ms)
  local total = math.max(math.ceil(ms / 1000), 0)
  local minutes = math.floor(total / 60)
  local seconds = total % 60
  return string.format("%02d:%02d", minutes, seconds)
end

local function mode_label()
  if M.state.mode == "paused" then
    return "PAUS"
  end

  if M.state.mode == "work" then
    return "WORK"
  end

  if M.state.mode == "short_break" or M.state.mode == "long_break" then
    return "REST"
  end

  return ""
end

local function replace_at(line, col, text)
  return vim.fn.strcharpart(line, 0, col - 1) .. text .. vim.fn.strcharpart(line, col - 1 + vim.fn.strchars(text))
end

local function overlay(frame, line, col, text)
  frame[line] = replace_at(frame[line], col, text)
end

local function set_mode(mode, duration)
  M.state.mode = mode
  M.state.previous_mode = nil
  M.state.remaining_ms = duration or duration_for(mode)
  M.state.ends_at = now_ms() + M.state.remaining_ms
  schedule_tick()
  redraw()
end

local function next_break_mode()
  local every = config.get("pomodoro.sessions_until_long_break") or 4
  if every > 0 and M.state.completed_sessions % every == 0 then
    return "long_break"
  end
  return "short_break"
end

function M.start(mode)
  if not config.get("pomodoro.enabled") then
    return false
  end

  set_mode(mode or "work")
  return true
end

function M.pause()
  if M.state.mode == "stopped" or M.state.mode == "paused" then
    return false
  end

  M.state.remaining_ms = math.max(M.state.ends_at - now_ms(), 0)
  M.state.previous_mode = M.state.mode
  M.state.mode = "paused"
  stop_timer()
  redraw()
  return true
end

function M.resume()
  if M.state.mode ~= "paused" or not M.state.previous_mode then
    return false
  end

  local mode = M.state.previous_mode
  M.state.mode = mode
  M.state.previous_mode = nil
  M.state.ends_at = now_ms() + M.state.remaining_ms
  schedule_tick()
  redraw()
  return true
end

function M.stop()
  M.state.mode = "stopped"
  M.state.previous_mode = nil
  M.state.remaining_ms = 0
  M.state.ends_at = 0
  stop_timer()
  redraw()
  return true
end

function M.tick()
  if M.state.mode == "stopped" or M.state.mode == "paused" then
    return
  end

  M.state.remaining_ms = math.max(M.state.ends_at - now_ms(), 0)
  if M.state.remaining_ms > 0 then
    redraw()
    return
  end

  stop_timer()

  if M.state.mode == "work" then
    M.state.completed_sessions = M.state.completed_sessions + 1
    vim.notify("Pomodoro complete. Time for a break.", vim.log.levels.INFO)
    if config.get("pomodoro.auto_start_breaks") then
      set_mode(next_break_mode())
    else
      M.stop()
    end
    return
  end

  vim.notify("Break complete. Time to focus.", vim.log.levels.INFO)
  if config.get("pomodoro.auto_start_work") then
    set_mode("work")
  else
    M.stop()
  end
end

function M.set_redraw(fn)
  M.state.redraw = fn
end

function M.remaining_ms()
  if M.state.mode == "stopped" then
    return 0
  end

  if M.state.mode == "paused" then
    return M.state.remaining_ms
  end

  return math.max(M.state.ends_at - now_ms(), 0)
end

function M.status()
  return {
    mode = M.state.mode,
    previous_mode = M.state.previous_mode,
    remaining_ms = M.remaining_ms(),
    remaining = format_time(M.remaining_ms()),
    completed_sessions = M.state.completed_sessions,
  }
end

function M.decorate(frame)
  if not config.get("pomodoro.enabled") or not config.get("pomodoro.show_timer") then
    return frame
  end

  if M.state.mode == "stopped" then
    return frame
  end

  local decorated = vim.deepcopy(frame)
  overlay(decorated, 1, 31, format_time(M.remaining_ms()))
  overlay(decorated, 2, 32, mode_label())
  return decorated
end

function M.cleanup()
  M.stop()
  M.state.redraw = nil
  if M.state.timer then
    M.state.timer:close()
    M.state.timer = nil
  end
end

return M
