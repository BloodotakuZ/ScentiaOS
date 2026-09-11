-- ============================================================
-- ScentiaOS XWayland / Gaming HiDPI
-- ============================================================

-- Keep the desktop at 2x scaling, but expose the monitor's
-- native pixel resolution to XWayland applications.
--
-- This allows Proton/XWayland games to see 3840x2160 instead
-- of being capped at the logical 1920x1080 size.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- Keep ordinary GTK/XWayland applications usable at 4K.
-- Wayland-native GTK applications are not adversely affected.
hl.env("GDK_SCALE", "2")
hl.env("XCURSOR_SIZE", "32")
