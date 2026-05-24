# bongodoro-cat.nvim

Neovim Bongo Cat plugin with a Unicode sprite, a floating window renderer, and a small animation engine for typing, idle, sleep, save, and error reactions. Pomodoro timer integration is planned.

## Features

- Alternates left/right frames while typing.
- Runs a randomized idle animation after 5-15 seconds without input.
- Enters sleep after 45 seconds without input.
- Shows a save reaction after `:write`.
- Can show an error reaction when diagnostics report errors.
- Renders in a configurable floating window.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "juanssanchezv/bongodoro-cat.nvim",
  opts = {
    auto_start = true,
  },
}
```

For local development:

```lua
{
  dir = "/path/to/bongodoro-cat.nvim",
  opts = {
    auto_start = true,
  },
}
```

## Configuration

```lua
require("bongo_cat").setup({
  auto_start = true,
  window = {
    position = "bottom-right",
    border = "rounded",
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
})
```

## Commands

- `:BongoCat` toggles the cat.
- `:BongoCat toggle` toggles the cat.
- `:BongoCat show` shows the cat.
- `:BongoCat hide` hides the cat.
- `:BongoCat status` prints setup/visibility status.

## Visual test

Launch Neovim with the local dev init to test the plugin in a real UI:

```sh
nvim -u ./scripts/minimal_init.lua
```

Suggested checks:

- enter Insert mode and type to verify `left` / `right` alternation
- stop typing and wait 5-15 seconds to verify the randomized idle animation
- wait 45 seconds without typing to verify `sleep`
- write a buffer with `:write` to verify the `save` reaction
- run `:lua require("bongo_cat.animator").on_event("error")` to verify the manual `error` reaction
- use `<leader>bt` to toggle the cat during testing

## Smoke Test

Run the headless smoke test before publishing or after changing frames:

```sh
nvim --headless -u NONE -l ./scripts/smoke_test.lua
```

Expected output:

```text
bongodoro-cat.nvim smoke ok: frames=36x12
```

## Roadmap

- Pomodoro timer integration with timer state shown in the animation.
