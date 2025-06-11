local LrTasks = import "LrTasks"
local catalog = import "LrApplication".activeCatalog()
local LrDevelopController = import 'LrDevelopController'
local ProgressScope = import "LrProgressScope"
local LrDialogs = import "LrDialogs"
local LrLogger = import "LrLogger"
local LrSelection = import "LrSelection"
local scriptName = "Auto Exposure"

-- Follow Lightroom Classic SDK Guide to see the logs
local myLogger = LrLogger("LRAutoExposureLogger")  -- log file name; will be in ~/Documents/LrClassicLogs/
-- myLogger:enable("logfile")
myLogger:enable("print")


function mylog(content)
    local label = scriptName
    myLogger:trace("[" .. label .. "] " .. content)
end

-- On one photo, auto adjust exposure
function processPhoto(photo)
    local fileName = photo:getFormattedMetadata("fileName")
    mylog("Processing image: ".. fileName)


    local format = photo:getRawMetadata("fileFormat")
    if format == "VIDEO" then
        return
    end

    -- sets auto tone, which will adjust more than just the exposure (we will fix that downstream)
    LrDevelopController:setAutoTone()
    mylog(fileName .. "Auto-Toned Success")

    local developSettings = photo:getDevelopSettings()
    

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
                -- mylog(string.format("%s, %s, %d", fileName, name, resetValueNum))

            elseif type(developSettings[name]) == "boolean" then 
                developSettings[name] = resetValueBool
                -- mylog(string.format("%s, %s, %d", fileName, name, resetValueBool))
            end
        end
        
        catalog:withWriteAccessDo(scriptName, function(context)
            photo:applyDevelopSettings(developSettings, scriptName, false)
        end)
end


LrTasks.startAsyncTask(function()
    local activeSources = catalog:getActiveSources()
    local numSources = #activeSources
    mylog("MAIN" .. "Number of active sources (collections/folders): " .. numSources)
    -- local photos = folder:getPhotos{ includeChildren = true }
    
    -- guardrail to only proceed if it is in the auto created watched folder
    if numSources ~= 1 or activeSources[1]:type() ~= "LrFolder" or activeSources[1]:getName() ~= 'Auto Imported Photos' then
        mylog(activeSources[1]:getName() .. " (" .. activeSources[1]:type() .. ") is not the 'Auto Imported Photos' in the watched folder!")
        return 
    end

    mylog("Source Type: " .. activeSources[1]:type() .. " name: " .. activeSources[1]:getName())
    local photos = activeSources[1]:getPhotos(true)
    local count = #photos
    mylog("Number of photos:" .. count)

    local progressScope = ProgressScope({ title = scriptName, caption = scriptName, })
    
    -- need to select all photos in folder to applying changes
    LrSelection:selectAll()
    mylog("Selected all photos in the folder")

    for i, photo in ipairs(photos) do
        processPhoto(photo)
        progressScope:setPortionComplete(i / count)
        progressScope:setCaption("Processing " .. i .. "/" .. count)
    end
    
    progressScope:done()
end )