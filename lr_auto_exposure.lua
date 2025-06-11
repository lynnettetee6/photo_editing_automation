local LrTasks = import "LrTasks"
local catalog = import "LrApplication".activeCatalog()
local LrDevelopController = import 'LrDevelopController'
local ProgressScope = import "LrProgressScope"
local LrDialogs = import "LrDialogs"
local LrLogger = import "LrLogger"

local scriptName = "Auto Develop"

-- Follow Lightroom Classic SDK Guide to see the logs
local myLogger = LrLogger("libraryLogger")  -- log file name; will be in ~/Documents/LrClassicLogs/
-- myLogger:enable("logfile")
-- myLogger:enable("print")


function mylog(content)
    local label = scriptName
    myLogger:trace("[" .. label .. "] " .. content)
end

-- On one photo, auto adjust exposure
function processPhoto(photo)
    local fileName = photo:getFormattedMetadata("fileName")
    local format = photo:getRawMetadata("fileFormat")
    if format == "VIDEO" then
        return
    end

    -- sets auto tone, which will adjust more than just the exposure (we will fix that downstream)
    LrDevelopController:setAutoTone()
    local developSettings = photo:getDevelopSettings() 
    
    local changed = false

    -- reset non-exposure values
    local resetSettingNames = {
            "Contrast2012",
            "Highlights2012",
            "Shadows2012",
            "Whites2012",
            "Blacks2012",
    
            "Sharpness",
            "Clarity",
            "Dehaze",
            
            "Vibrance",
            "Saturation",
        } -- "SharpenDetail", "Brightness", "HighlightRecovery"
        
        local resetValueNum = 0
        local resetValueBool = false -- Autox params (bool)
        for i, name in ipairs(resetSettingNames) do
            if type(developSettings[name]) == "number" then 
                developSettings[name] = resetValueNum

            elseif type(developSettings[name]) == "boolean" then 
                developSettings[name] = resetValueBool
            end
        end
    
        catalog:withWriteAccessDo(scriptName, function(context)
            photo:applyDevelopSettings(developSettings, scriptName, false)
        end 
end


LrTasks.startAsyncTask(function()
    local photos = catalog:getTargetPhotos()
    local count = #photos

    local progressScope = ProgressScope({ title = scriptName, caption = scriptName, })
    
    for i, photo in ipairs(photos) do
        processPhoto(photo)
        progressScope:setPortionComplete(i / count)
        progressScope:setCaption("Processing " .. i .. "/" .. count)
    end
    
    progressScope:done()
end )