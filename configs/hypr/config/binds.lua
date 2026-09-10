-- ============================================================
-- ScentiaOS keybinds
-- ============================================================

-- Default browser
hl.bind(
    "SUPER + E",
    hl.dsp.exec_cmd(
        [[uwsm app -- sh -lc 'exec gtk-launch "$(xdg-settings get default-web-browser)"']]
    )
)

-- Terminal
hl.bind(
    "SUPER + Return",
    hl.dsp.exec_cmd("uwsm app -- kitty")
)

-- File manager
hl.bind(
    "SUPER + W",
    hl.dsp.exec_cmd("uwsm app -- thunar")
)

-- Gracefully close active window
hl.bind(
    "SUPER + Q",
    hl.dsp.window.close()
)

-- Force kill active window
hl.bind(
    "SUPER + SHIFT + Q",
    hl.dsp.window.kill()
)

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind(
        "SUPER + " .. i,
        hl.dsp.focus({ workspace = i })
    )
end
