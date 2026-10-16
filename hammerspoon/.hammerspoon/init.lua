local hyper = { "cmd", "ctrl", "alt" }

hs.autoLaunch(true)
-- Move instantly, matching AeroSpace instead of macOS animation.
hs.window.animationDuration = 0

-- Center a floating window without duplicating AeroSpace tiling commands.
hs.hotkey.bind(hyper, "c", function()
  local window = hs.window.focusedWindow()
  if window then
    window:centerOnScreen()
  end
end)
