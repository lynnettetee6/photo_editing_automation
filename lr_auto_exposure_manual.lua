local LrTasks = import "LrTasks"
local catalog = import "LrApplication":activeCatalog()
local LrApplicationView = import "LrApplicationView"
local LrDevelopController = import 'LrDevelopController'
local ProgressScope = import "LrProgressScope"
local LrDialogs = import "LrDialogs"
local LrLogger = import "LrLogger"
local LrSelection = import "LrSelection"
local scriptName = "Auto Exposure Manual"

-- Follow Lightroom Classic SDK Guide to see the logs
local myLogger = LrLogger("LRAutoExposureManualLogger")  -- log file name; will be in ~/Documents/LrClassicLogs/
-- myLogger:enable("logfile")
myLogger:enable("print")



function mylog(content)
    local label = scriptName
    myLogger:trace("[" .. label .. "] " .. content)
end

-- On one photo, auto adjust exposure
function isVideo(photo)
    if photo:getRawMetadata("fileFormat") == "VIDEO" then
        mylog(photo:getFormattedMetadata("fileName") .. "not processed as it is a video")
        return true
    end

    return false
end

function autoTone(photo)
    local fileName = photo:getFormattedMetadata("fileName")
    mylog("Auto Tone image: ".. fileName)
    LrDevelopController:setAutoTone()
    mylog(fileName .. "Auto-Toned Success")
end

function resetAllButExposure(photo)
    local fileName = photo:getFormattedMetadata("fileName")
    mylog("Reset All but Exposure for image: ".. fileName)
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
        mylog(fileName .. "Auto-Reset Success")
end


LrTasks.startAsyncTask(function()
    -- Show in library view rather than develop view
    mylog('-----AUTO EXPOSURE MANUAL MODE-----')

    LrApplicationView.switchToModule('library')
    mylog('Switched to library module')
    LrApplicationView.gridView()
    mylog('Switched to grid view')

    local photos = catalog:getTargetPhotos()
    local count = #photos
    mylog("Number of photos:" .. count)

    local progressScope = ProgressScope({ title = scriptName, caption = scriptName, })
    -- need to select all photos in folder to applying changes
    LrSelection:selectAll()
    mylog("Selected all photos in the folder")

    for i, photo in ipairs(photos) do
        if not isVideo(photo) then
            autoTone(photo)
            progressScope:setPortionComplete(i / count)
            progressScope:setCaption("AutoTone " .. i .. "/" .. count)
        end
    end
    for i, photo in ipairs(photos) do
        if not isVideo(photo) then
            resetAllButExposure(photo)
            progressScope:setPortionComplete(i / count)
            progressScope:setCaption("Reset all but Exposure " .. i .. "/" .. count)
        end
    end
    progressScope:done()
end )