-- ============================================================
-- ScentiaOS Keybinds
-- ============================================================

-- ------------------------------------------------------------
-- Applications
-- ------------------------------------------------------------

-- SUPER + E -> default browser
hl.bind(
    "SUPER + E",
    hl.dsp.exec_cmd(
        [[gtk-launch "$(xdg-settings get default-web-browser | sed 's/\.desktop$//')"]]
    )
)

-- SUPER + W -> Thunar
hl.bind(
    "SUPER + W",
    hl.dsp.exec_cmd("thunar")
)

-- SUPER + RETURN -> Kitty
hl.bind(
    "SUPER + Return",
    hl.dsp.exec_cmd("kitty")
)

-- SUPER + SPACE -> Noctalia application launcher
hl.bind(
    "SUPER + Space",
    hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")
)

-- ------------------------------------------------------------
-- Window controls
-- ------------------------------------------------------------

-- SUPER + Q -> graceful close
hl.bind(
    "SUPER + Q",
    hl.dsp.window.close()
)

-- SUPER + SHIFT + Q -> force kill
hl.bind(
    "SUPER + SHIFT + Q",
    hl.dsp.window.kill()
)

-- ------------------------------------------------------------
-- Focus tiled windows
-- ------------------------------------------------------------

-- SUPER + arrow -> focus tile in that direction
hl.bind("SUPER + Left",  hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + Up",    hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + Down",  hl.dsp.focus({ direction = "d" }))

-- ------------------------------------------------------------
-- Workspaces 1-9
-- ------------------------------------------------------------

for i = 1, 9 do
    -- SUPER + number -> switch workspace
    hl.bind(
        "SUPER + " .. i,
        hl.dsp.focus({ workspace = i })
    )

    -- SUPER + SHIFT + number -> move active tile to workspace
    hl.bind(
        "SUPER + SHIFT + " .. i,
        hl.dsp.window.move({
            workspace = i,
            follow = false
        })
    )
end

-- ------------------------------------------------------------
-- Relative workspace switching
-- ------------------------------------------------------------

-- SUPER + SHIFT + Left -> previous numbered workspace
hl.bind(
    "SUPER + SHIFT + Left",
    hl.dsp.focus({ workspace = "-1" })
)

-- SUPER + SHIFT + Right -> next numbered workspace
hl.bind(
    "SUPER + SHIFT + Right",
    hl.dsp.focus({ workspace = "+1" })
)

-- ------------------------------------------------------------
-- Move active tile between adjacent workspaces
-- ------------------------------------------------------------

-- SUPER + CTRL + Left -> move tile one workspace back
hl.bind(
    "SUPER + CTRL + Left",
    hl.dsp.window.move({
        workspace = "-1",
        follow = false
    })
)

-- SUPER + CTRL + Right -> move tile one workspace forward
hl.bind(
    "SUPER + CTRL + Right",
    hl.dsp.window.move({
        workspace = "+1",
        follow = false
    })
)

-- SUPER + TAB -> application/window switcher
hl.bind(
    "SUPER + Tab",
    hl.dsp.exec_cmd("noctalia msg window-switcher")
)

-- SUPER + F -> toggle fullscreen on active tile
hl.bind(
    "SUPER + F",
    hl.dsp.window.fullscreen({
        mode = "fullscreen",
        action = "toggle"
    })
)

-- SUPER + S -> region screenshot
hl.bind(
    "SUPER + S",
    hl.dsp.exec_cmd("noctalia msg screenshot-region")
)
