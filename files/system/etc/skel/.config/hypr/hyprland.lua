-- ============================================================
-- ScentiaOS Hyprland
-- ============================================================

require("config.variables")
require("config.monitors")
require("config.appearance")
require("config.binds")

-- Noctalia
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia --daemon")
end)
