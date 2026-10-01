-- Window rules wiki https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-----------------
---- GENERIC ----
-----------------

-- Generic floating position
hl.window_rule({
    match = { float = true },
    center = true,
    persistent_size = true,
})

----------------
---- OCTGN ----
----------------

-- OCTGN (Wine WPF app) windows should float on top of each other
-- rather than tile, since the lobby and game table are separate
-- windows that don't make sense side-by-side.
hl.window_rule({
    match = {
        class = "^(octgn)$",
    },
    float = true,
    center = true,
})

----------------------------
---- PICTURE-IN-PICTURE ----
----------------------------

hl.window_rule({
    match = {
        title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
    },
    float = true,
    keep_aspect_ratio = true,
    size = {
        "max(monitor_w, monitor_h)*0.25",
               "min(monitor_w, monitor_h)*0.25"
    },
    pin = true,
})

----------------
---- GAMING ----
----------------

-- Workspace 9 is reserved for games
local gamingApps = "^(steam_app.*|gamescope)$"
local gamingWorkspace = "9"

-- Send anything Hyprland identifies as a game to workspace 9
hl.window_rule({
    match = {
        content = "game"
    },
    workspace = gamingWorkspace,
})

-- Tagged game windows
hl.window_rule({
    match = {
        xdg_tag = "^(.*game.*)$"
    },
    workspace = gamingWorkspace,
    fullscreen_state = 2,
    content = "game",
    sync_fullscreen = true,
})

-- Steam games / Gamescope
hl.window_rule({
    match = {
        class = gamingApps
    },
    workspace = gamingWorkspace,
})

-- Steam Friends List
hl.window_rule({
    match = {
        class = "^(steam)$",
               title = "^(Friends List)$"
    },
    float = true,
})

-- Steam launching dialog
hl.window_rule({
    match = {
        class = "^(steam)$",
               title = "^(Launching\\.{3})$"
    },
    float = true,
    center = true,
    workspace = gamingWorkspace,
})

-- Game fullscreen behavior
hl.window_rule({
    match = {
        class = gamingApps,
        title = "^(.+)$",
               initial_title = "negative:^(.*\\\\home\\\\.*)$",
    },
    content = "game",
    decorate = false,
    fullscreen_state = 2,
    size = {
        "monitor_w",
        "monitor_h"
    },
    sync_fullscreen = true,
})

-- Handle Steam game windows that initially appear without a title
hl.window_rule({
    match = {
        class = "^(steam_app.*)$",
               initial_title = "^$",
    },
    center = true,
    float = true,
    fullscreen = false,
    fullscreen_state = 0,
    workspace = gamingWorkspace,
})

--------------
---- APPS ----
--------------

-- Windows executables
hl.window_rule({
    match = {
        class = "^(.*\\.exe)$"
    },
    float = true,
    monitor = PRIMARY_MONITOR,
    center = true,
    fullscreen_state = 0,
})

-- Launchers
hl.window_rule({
    match = {
        class = "^(.*[Ll]auncher.*)$"
    },
    float = true,
    monitor = PRIMARY_MONITOR,
})

-- Discord / Vesktop
hl.window_rule({
    match = {
        class = "^(vesktop|discord)$"
    },
    monitor = PRIMARY_MONITOR,
})

-- Calculators
hl.window_rule({
    match = {
        class = "^(.*[Cc]alc.*)$"
    },
    float = true,
    size = {
        "max(monitor_w, monitor_h)*0.17",
               "min(monitor_w, monitor_h)*0.43"
    },
})

-- KDE file type editor
hl.window_rule({
    match = {
        class = "^(org\\.kde\\.keditfiletype)$"
    },
    float = true,
})

-- Ark
hl.window_rule({
    match = {
        class = "^(org\\.kde\\.ark)$"
    },
    size = {
        "max(monitor_w, monitor_h)*0.40",
               "min(monitor_w, monitor_h)*0.40"
    },
})

-- Satty
hl.window_rule({
    match = {
        class = "^(.*satty.*)$",
               title = "^(Satty)$"
    },
    min_size = {
        "max(monitor_w, monitor_h)*0.35",
               "min(monitor_w, monitor_h)*0.35"
    },
    float = true,
})

-- Noctalia settings
hl.window_rule({
    match = {
        class = "^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$"
    },
    float = true,
    size = {
        "monitor_w*0.70",
        "monitor_h*0.70"
    },
})

-- Dolphin
hl.window_rule({
    match = {
        class = "^(org\\.kde\\.dolphin)$",
               title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
    },
    float = true,
    size = {
        "max(monitor_w, monitor_h)*0.50",
               "min(monitor_w, monitor_h)*0.55"
    },
    move = {
        "max(20, min(cursor_x - (window_w*0.50), monitor_w - window_w + 20))",
               "max(20, min(cursor_y - 50, monitor_h - window_h + 20))"
    },
})

---------------------------
---- OPACITY OVERRIDES ----
---------------------------

local terminals = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$"

-- Browsers
hl.window_rule({
    match = {
        class = "^(firefox|zen)$"
    },
    opacity = "1.0 override",
})

-- Terminals
hl.window_rule({
    match = {
        class = terminals
    },
    opacity = "1.0 override",
})

-- Media players
hl.window_rule({
    match = {
        class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$"
    },
    opacity = "1.0 override",
})

-------------------------------
---- FLOAT UTILITY WINDOWS ----
-------------------------------

local floatApps = {
    {
        class = "^(kvantummanager|qt[56]ct|nwg-look)$"
    },
    {
        class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$"
    },
    {
        title = "^(Winetricks.*|Protontricks.*)$"
    },
}

for _, m in ipairs(floatApps) do
    hl.window_rule({
        match = m,
        float = true,
    })
    end

    -----------------------------
    ---- FLOAT COMMON MODALS ----
    -----------------------------

    local modalMatches = {
        {
            title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$"
        },
        {
            initial_title = "^(Open File)$"
        },
        {
            class = "^([Xx]dg-desktop-portal-gtk)$"
        },
        {
            title = "^(File Upload|Choose wallpaper|Library)(.*)$"
        },
        {
            class = "^(.*dialog.*)$"
        },
        {
            title = "^(.*dialog.*)$"
        },
        {
            class = "^(hyprland-share-picker)$"
        },
    }

    for _, m in ipairs(modalMatches) do
        hl.window_rule({
            match = m,
            float = true,
        })
        end

        -------------------
        ---- BEHAVIOR ----
        -------------------

        -- Ignore maximize requests from all apps
        hl.window_rule({
            name = "suppress-maximize-events",
            match = {
                class = ".*"
            },
            suppress_event = "maximize",
        })

        -- Fix some dragging issues with XWayland
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
