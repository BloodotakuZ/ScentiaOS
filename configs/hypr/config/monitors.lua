-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = MONITOR1,
--     mode      = "3840x2160@120",
--     position  = "0x0",
--     scale     = "2",
-- })

hl.monitor({
    output    = MONITOR1,
    mode      = "3840x2160@120",
    position  = "auto",
    scale     = "2",
})
