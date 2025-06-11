local LrTasks = import "LrTasks"
local catalog = import "LrApplication".activeCatalog()
-- local activeSources = import "LrApplication".activeCatalog().getActiveSources()
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
    -- print("[" .. label .. "] " .. content)
    myLogger:trace("[" .. label .. "] " .. content)
end


function setDevelopSettings(settings, key, value)
    local changed = false
    local original = settings[key]
    if original ~= value then
        settings[key] = value
        changed = true
    end
    return changed
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

    -- local resetSettingNames = {"Vibrance", "Exposure2012"}

        for i, name in ipairs(resetSettingNames) do
            if type(developSettings[name]) == "number" then 
                local ret = setDevelopSettings(developSettings, name, 0)
                changed = changed or ret
            end
            if type(developSettings[name]) == "boolean" then 
                local ret = setDevelopSettings(developSettings, name, false)
                changed = changed or ret
            end
        end
        
        if changed then
            catalog:withWriteAccessDo(scriptName, function(context)
                photo:applyDevelopSettings(developSettings, scriptName, false)
            end )
        end
        
        
        
        -- photo:quickDevelopAdjustImage("Exposure","large")
        -- photo:applyDevelopSettings({ AutoExposure = true, })
        


    -- for name, val in pairs(developSettings) do
    --     if name ~= "Exposure" and type(val) == "number" then 
    --         developSettings[name] = 0
    --     end
    --     if not string.find(name, "^Auto") and type(val) == "boolean" then
    --         developSettings[name] = false
    --     end
    -- end

    -- catalog:withWriteAccessDo(scriptName, function(context)
    --     photo:applyDevelopSettings(developSettings, scriptName, false)
    -- end )







    -- -- reset all other adjustments; keep exposure change only
    

    -- catalog:withWriteAccessDo(scriptName, function(context)
    --     photo:applyDevelopSettings(resetSettings, scriptName, false)
    -- end )
    
    
  
    -- -- check if settings are applied
    -- for settingName, settingValue in pairs(photo:getDevelopSettings()) do
    --     if settingName ~= "Exposure" and type(settingValue) == "number" and settingValue ~= 0 then
    --         mylog(string.format("  Non-Exposure setting '%s' has a non-zero value: %s", settingName, tostring(settingValue)))
    -- end
    

end


LrTasks.startAsyncTask(function()
    local photos = catalog:getTargetPhotos()
    
    -- local numSources = #activeSources
    -- mylog("MAIN" .. "Number of active sources (collections/folders): " .. numSources)
    -- -- local photos = folder:getPhotos{ includeChildren = true }

    -- if numSources > 1 then 
    --     mylog("MAIN" .. "No handling available yet for more than one active source. Action aborted." .. numSources)
    --     return -- TODO patch this
    -- end
    
    -- assert(numSources[1]:isKindOf("LrFolder"), "Expected first active source to be LrFolder, but it was instead a " .. numSources[1]:getType())

    -- local photos = numSources[1].getPhotos()

    local count = #photos

    --[[
    prompt = "Will apply auto develop settings to " .. count .. " photo(s)..."
    local ret = LrDialogs.confirm(scriptName, prompt)
    if ret ~= "ok" then
        return
    end
    ]]

    local progressScope = ProgressScope({ title = scriptName, caption = scriptName, })
    

    for i, photo in ipairs(photos) do
        processPhoto(photo)
        -- LrTasks.sleep(2)    -- Simulate a time-consuming operation, to check whether the ProgressScope updates correctly.
        progressScope:setPortionComplete(i / count)
        progressScope:setCaption("Processing " .. i .. "/" .. count)
    end
    

    progressScope:done()
end )