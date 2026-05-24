local config = require("bongo_cat.config")
local frames = require("bongo_cat.frames")

local M = {
  state = {
    buf = nil,
    win = nil,
  },
}

local function current_ui()
  return vim.api.nvim_list_uis()[1]
end

local function dimensions()
  local width = config.get("window.width")
  local height = config.get("window.height")
  if width and height then
    return width, height
  end
  return frames.dimensions()
end

local function border_padding()
  local border = config.get("window.border")
  if not border or border == "none" then
    return 0
  end

  return 2
end

local function get_position()
  local ui = current_ui()
  if not ui then
    return 0, 0
  end

  local width, height = dimensions()
  local pos = config.get("window.position")
  local margin_x = config.get("window.margin_x") or 1
  local margin_y = config.get("window.margin_y") or 1
  local border = border_padding()

  local row = ui.height - height - margin_y - border
  local col = ui.width - width - margin_x - border

  if pos == "top-left" then
    row, col = margin_y, margin_x
  elseif pos == "top-right" then
    row, col = margin_y, ui.width - width - margin_x - border
  elseif pos == "bottom-left" then
    row, col = ui.height - height - margin_y - border, margin_x
  end

  return math.max(row, 0), math.max(col, 0)
end

local function ensure_buf()
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    return M.state.buf
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  M.state.buf = buf
  return buf
end

function M.open()
  if M.is_visible() then
    return true
  end

  if not current_ui() then
    return false
  end

  local buf = ensure_buf()
  local width, height = dimensions()
  local row, col = get_position()

  M.state.win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.get("window.border"),
    zindex = config.get("window.zindex"),
  })

  vim.wo[M.state.win].winblend = config.get("window.winblend")
  vim.wo[M.state.win].wrap = false
  vim.wo[M.state.win].number = false
  vim.wo[M.state.win].relativenumber = false
  vim.wo[M.state.win].signcolumn = "no"
  vim.wo[M.state.win].cursorline = false

  return true
end

function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil
end

function M.is_visible()
  return M.state.win and vim.api.nvim_win_is_valid(M.state.win) or false
end

function M.render(frame)
  if not M.is_visible() then
    return
  end

  if not (M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf)) then
    return
  end

  local width, height = dimensions()
  local lines = {}

  for _, line in ipairs(frame) do
    local display_width = vim.fn.strdisplaywidth(line)
    if display_width < width then
      line = line .. string.rep(" ", width - display_width)
    end
    table.insert(lines, line)
  end

  while #lines < height do
    table.insert(lines, string.rep(" ", width))
  end

  vim.bo[M.state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.bo[M.state.buf].modifiable = false
end

function M.reposition()
  if not M.is_visible() then
    return
  end

  local row, col = get_position()
  vim.api.nvim_win_set_config(M.state.win, {
    relative = "editor",
    row = row,
    col = col,
  })
end

return M
