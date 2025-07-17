local LrTasks = import "LrTasks"
local catalog = import "LrApplication":activeCatalog()
local LrApplicationView = import "LrApplicationView"
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

-- Load environment variables from .env file
local function loadEnvFile(path)
    local env = {}
    local file = io.open(path, "r")
    if not file then
        mylog("Could not open .env file at: " .. path)
        return env
    end
    for line in file:lines() do
        local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if key and value then
            -- Remove surrounding single or double quotes
            value = value:match("^['\"](.+)['\"]$") or value
            env[key] = value
        end
    end
    file:close()
    return env
end
mylog("Read env file")
local envPath = '/Users/lynnettetee/Library/Mobile Documents/com~apple~CloudDocs/ml_projects/photo_edit_automation/.env'
local env = loadEnvFile(envPath)
local targetFolderPath = env['LR_AUTO_IMPORT_DEST']


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
    -- 1. Show in library view rather than develop view
    LrApplicationView.switchToModule('library')
    mylog('Switched to library module')
    LrApplicationView.gridView()
    mylog('Switched to grid view')
    
    -- 2. Select the target folder as the active view
    local autoImportFolder = catalog:getFolderByPath(targetFolderPath)
    if not autoImportFolder then
        mylog("autoImportFolder not found: " .. targetFolderPath)
        LrDialogs.message("Error", "autoImportFolder not found: " .. targetFolderPath, "critical")
        return
    end
    
    catalog:setActiveSources({autoImportFolder})
    mylog("Set folder as active: " .. autoImportFolder:getPath())
    
    

    -- 3. Select all photos in target folder before applying changes
    catalog:setSelectedPhotos(autoImportFolder:getPhotos(true)[1], autoImportFolder:getPhotos(true))
    -- LrSelection.selectNone()
    LrSelection.selectAll() -- in case setSelectedPhotos does not work
    mylog("Selected all photos in active folder")
    
    -- -- 4. Apply auto exposure changes
    -- local photos = autoImportFolder:getPhotos(true)
    local photos = catalog:getTargetPhotos() -- returns the list of selected photos (in 3.)
    local count = #photos
    mylog("Number of photos:" .. count)

    local progressScope = ProgressScope({ title = scriptName, caption = scriptName, })
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
    mylog("Auto Exposure COMPLETE")
end )