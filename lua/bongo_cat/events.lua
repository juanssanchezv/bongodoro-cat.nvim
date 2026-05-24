local animator = require("bongo_cat.animator")
local config = require("bongo_cat.config")
local window = require("bongo_cat.window")

local M = {
  state = {
    augroup = nil,
    ns = nil,
  },
}

local function mode_is_enabled(mode)
  local prefixes = config.get("input.enabled_mode_prefixes") or {}

  for _, prefix in ipairs(prefixes) do
    if vim.startswith(mode, prefix) then
      return true
    end
  end

  return false
end

local function is_countable_key(key)
  if not key or key == "" then
    return false
  end

  local translated = vim.fn.keytrans(key)
  if translated == "" then
    return false
  end

  if translated == "<Space>" then
    return config.get("input.count_space")
  end

  if translated == "<Tab>" then
    return config.get("input.count_tab")
  end

  if translated == "<CR>" then
    return config.get("input.count_enter")
  end

  if translated == "<BS>" or translated == "<Del>" then
    return config.get("input.count_backspace")
  end

  if translated:match("^<.*>$") then
    return false
  end

  return vim.fn.strchars(key) > 0
end

local function on_key(key)
  if not window.is_visible() then
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if not mode_is_enabled(mode) then
    return
  end

  if not is_countable_key(key) then
    return
  end

  animator.on_input()
end

local function on_save()
  if not window.is_visible() then
    return
  end

  if not config.get("events.save") then
    return
  end

  animator.on_event("save")
end

local function on_error(args)
  if not window.is_visible() then
    return
  end

  if not config.get("events.error") then
    return
  end

  local diagnostics = vim.diagnostic.get(args.buf, { severity = vim.diagnostic.severity.ERROR })
  if #diagnostics > 0 then
    animator.on_event("error")
  end
end

function M.setup()
  M.state.augroup = vim.api.nvim_create_augroup("BongoCat", { clear = true })
  M.state.ns = vim.api.nvim_create_namespace("bongo-cat")

  vim.on_key(on_key, M.state.ns)

  vim.api.nvim_create_autocmd("VimResized", {
    group = M.state.augroup,
    callback = function()
      window.reposition()
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = M.state.augroup,
    callback = on_save,
  })

  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = M.state.augroup,
    callback = on_error,
  })
end

function M.cleanup()
  if M.state.ns then
    vim.on_key(nil, M.state.ns)
  end

  if M.state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, M.state.augroup)
    M.state.augroup = nil
  end
end

return M
