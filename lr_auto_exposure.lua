local LrTasks = import "LrTasks"
local catalog = import "LrApplication":activeCatalog()
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

-- TODO fix: use .env to get targetFolderPath

local targetFolderPath = '/Users/lynnettetee/Documents/eg_fuji/eg_fuji_edit/AutoImport' -- WARNING! Change this to your actual path

-- Load environment variables from .env file
-- local function loadEnvFile(path)
--     local env = {}
--     local file = io.open(path, "r")
--     if not file then
--         mylog("Could not open .env file at: " .. path)
--     end
--     for line in file:lines() do
--         local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
--         if key and value then
--             env[key] = value
--         end
--     end
--     file:close()
--     return env
-- end
-- local envPath = '/Users/lynnettetee/Library/Mobile Documents/com~apple~CloudDocs/ml_projects/photo_edit_automation/.env' -- WARNING! Change this to your actual path
-- local env = loadEnvFile(envPath)
-- local ROOT_DIR = env['ROOT_DIR']
-- local DEST = env['DEST']
-- local EDIT = env['EDIT_PATHNAME']
-- local LR_AUTO_IMPORT_DIR = env['LR_AUTO_IMPORT_DIR']

-- local targetFolderPath = string.format("%s_%s/%s", DEST, EDIT, LR_AUTO_IMPORT_DIR)


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
    -- navigate to the target folder
    mylog("Navigating to target folder: "..targetFolderPath)

    local autoImportFolder = catalog:getFolderByPath(targetFolderPath)
    mylog("Folder path: " .. autoImportFolder:getPath())
    
    if not autoImportFolder then
        mylog("autoImportFolder not found: " .. targetFolderPath)
        LrDialogs.message("Error", "autoImportFolder not found: " .. targetFolderPath, "critical")
        return
    end
    mylog("Found autoImportFolder: " .. autoImportFolder:getName() .. " at path: " .. autoImportFolder:getPath())

    -- start processing photos in the folder
    -- -- guardrail to only proceed if it is in the auto created watched folder
    -- if numSources ~= 1 or activeSources[1]:type() ~= "LrFolder" or activeSources[1]:getName() ~= 'Auto Imported Photos' then
    --     mylog(activeSources[1]:getName() .. " (" .. activeSources[1]:type() .. ") is not the 'Auto Imported Photos' in the watched folder!")
    --     return 
    -- end

    -- mylog("Source Type: " .. activeSources[1]:type() .. " name: " .. activeSources[1]:getName())


    local photos = autoImportFolder:getPhotos(true)
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