-- ============================================================
-- ScentiaOS Hyprland Configuration
-- ============================================================

-- ------------------------------------------------------------
-- Startup
-- ------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Start Noctalia
    hl.exec_cmd("noctalia --daemon")
end)


-- ------------------------------------------------------------
-- Applications
-- ------------------------------------------------------------

-- SUPER + E
-- Open the system's DEFAULT web browser.
-- We deliberately do not hardcode Firefox/Chrome/etc.
hl.bind(
    "SUPER + E",
    hl.dsp.exec_cmd(
        [[uwsm app -- sh -lc 'exec gtk-launch "$(xdg-settings get default-web-browser)"']]
    )
)

-- SUPER + RETURN
-- Terminal
hl.bind(
    "SUPER + Return",
    hl.dsp.exec_cmd("uwsm app -- kitty")
)


-- ------------------------------------------------------------
-- Workspaces
-- ------------------------------------------------------------

-- SUPER + 1 through SUPER + 9
for i = 1, 9 do
    hl.bind(
        "SUPER + " .. i,
        hl.dsp.focus({ workspace = i })
    )
end
