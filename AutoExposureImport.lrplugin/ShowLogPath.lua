-- ShowLogPath.lua
-- This script is executed when the "View Auto Exposure Log Path" menu item is selected.
-- Note: The menu item title in Info.lua might still say "Auto Exposure Log Path".
-- You might want to update that in Info.lua to "View Auto Exposure Log Path" for consistency.

local LrDialogs = import 'LrDialogs'

-- Retrieve the log path stored globally by AutoExposureTask.lua
local logFilePath = _G.autoExposurePluginLogPath -- Updated global variable name

local pluginName = "Auto Exposure on Import Plugin" -- Updated plugin name for messages

if logFilePath then
    LrDialogs.showMessage(
        pluginName .. " - Log Path", -- Dialog title
        "The log file for the " .. pluginName .. " is configured to be at:\n\n" ..
        logFilePath ..
        "\n\nIf the file doesn't exist, it might be because no photos have been imported since Lightroom started, " ..
        "or there was an issue initializing the logger (check Lightroom's main console if developer mode is on).",
        "OK" -- Button label
    )
else
    LrDialogs.showMessage(
        pluginName .. " - Log Path",
        "The log file path is not currently available. The plugin might not have initialized correctly.",
        "OK"
    )
end