local M = {}

local health = vim.health or {}

local function start(name)
  if health.start then
    health.start(name)
  else
    health.report_start(name)
  end
end

local function ok(message)
  if health.ok then
    health.ok(message)
  else
    health.report_ok(message)
  end
end

local function warn(message)
  if health.warn then
    health.warn(message)
  else
    health.report_warn(message)
  end
end

local function error(message)
  if health.error then
    health.error(message)
  else
    health.report_error(message)
  end
end

local function check_require(module)
  local loaded, result = pcall(require, module)
  if loaded then
    ok("Loaded " .. module)
    return result
  end

  error("Failed to load " .. module .. ": " .. tostring(result))
  return nil
end

function M.check()
  start("bongodoro-cat.nvim")

  if vim.fn.has("nvim-0.9") == 1 then
    ok("Neovim version is supported")
  else
    warn("Neovim 0.9+ is recommended")
  end

  if vim.uv or vim.loop then
    ok("libuv timer API is available")
  else
    error("libuv timer API is unavailable")
  end

  local config = check_require("bongo_cat.config")
  local frames = check_require("bongo_cat.frames")
  check_require("bongo_cat.window")
  check_require("bongo_cat.animator")
  check_require("bongo_cat.events")
  check_require("bongo_cat.pomodoro")

  if frames then
    local width, height = frames.dimensions()
    if width > 0 and height > 0 then
      ok(string.format("Frame dimensions are %dx%d", width, height))
    else
      error("Frame dimensions are invalid")
    end

    for _, name in ipairs(frames.order) do
      local frame = frames.get(name)
      if #frame == height then
        ok("Frame " .. name .. " has expected height")
      else
        error(string.format("Frame %s has height %d, expected %d", name, #frame, height))
      end
    end
  end

  if config then
    local options = config.get()
    if options.auto_start then
      ok("auto_start is enabled")
    else
      ok("auto_start is disabled")
    end

    if options.pomodoro and options.pomodoro.enabled then
      ok("Pomodoro is enabled")
    else
      warn("Pomodoro is disabled")
    end

    if options.events and options.events.error then
      warn("Diagnostic error animation is enabled and may be noisy while typing")
    else
      ok("Diagnostic error animation is disabled by default")
    end
  end
end

return M
