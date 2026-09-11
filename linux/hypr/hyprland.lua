hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

local terminal = "kitty"
local file_manager = "dolphin"
local launcher = "hyprlauncher"
local main_mod = "SUPER"

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprlauncher -d")
    hl.exec_cmd("dunst")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("systemctl --user start --no-block hyprpolkitagent.service")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(7aa2f7ee)", "rgba(7dcfffee)" }, angle = 45 },
            inactive_border = "rgba(565f89aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.17,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        kb_options = "ctrl:nocaps",
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.08,
        },
    },
    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOut", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4.8, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.5, bezier = "easeInOut", style = "popin 85%" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.0, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.0, bezier = "easeOutQuint", style = "fade" })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + R", hl.dsp.exec_cmd(launcher))
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(main_mod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))

hl.bind(main_mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(main_mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(main_mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(main_mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }))
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd("sh -c 'mkdir -p \"$HOME/Pictures\"; grim \"$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png\"'"))
hl.bind(main_mod .. " + Print", hl.dsp.exec_cmd("sh -c 'geometry=$(slurp) || exit; mkdir -p \"$HOME/Pictures\"; grim -g \"$geometry\" \"$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png\"'"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
