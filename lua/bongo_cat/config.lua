local M = {}

M.defaults = {
  window = {
    position = "bottom-right",
    border = "rounded",
    winblend = 0,
    zindex = 60,
    margin_x = 1,
    margin_y = 1,
  },
  animation = {
    idle_delay_min = 5000,
    idle_delay_max = 15000,
    idle_min_cycles = 2,
    idle_max_cycles = 8,
    idle_frame_tick = 120,
    sleep_timeout = 45000,
    sleep_tick = 700,
    event_tick = 700,
  },
  events = {
    save = true,
    error = false,
  },
  input = {
    enabled_mode_prefixes = { "i", "R", "c", "r" },
    count_backspace = true,
    count_enter = true,
    count_tab = true,
    count_space = true,
  },
  auto_start = true,
  keymaps = {
    toggle = "<leader>bc",
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

function M.get(path)
  if not path then
    return M.options
  end

  local value = M.options
  for _, key in ipairs(vim.split(path, ".", { plain = true })) do
    if type(value) ~= "table" then
      return nil
    end

    value = value[key]
  end
  return value
end

return M
