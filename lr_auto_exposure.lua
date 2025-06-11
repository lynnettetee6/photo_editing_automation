local LrTasks = import "LrTasks"
local catalog = import "LrApplication".activeCatalog()
local activeSources = import "LrApplication".activeCatalog().getActiveSources()
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


-- Handles one photo
function processPhoto(photo)
    local fileName = photo:getFormattedMetadata("fileName")
    local format = photo:getRawMetadata("fileFormat")
    if format == "VIDEO" then
        return
    end

    local iso = photo:getRawMetadata("isoSpeedRating")  -- a number
    if iso == nil then
        mylog(fileName .. ": unable to get ISO speed")
        return
    end

    local changed = false
    local developSettings = photo:getDevelopSettings()  -- a table
    local factor = 33    -- ISO <= 100: Luminance NR = 5; ISO >= 1000: Luminance NR = 30

    -- Luminance noise always exists. So limit the min value.
    -- Luminance noise reduction becomes less effective when > 30
    local luminanceNoiseReductionMin, luminanceNoiseReductionMax = 5, 30

    -- Convert to integer to prevent fake changed value in `setDevelopSettings()`
    -- Seems Lightroom internal Lua interpreter does not support `//` operator: unexpected symbol near '/'
    local luminanceNoiseReduction = math.floor(iso / factor)

    if luminanceNoiseReduction < luminanceNoiseReductionMin then
        luminanceNoiseReduction = luminanceNoiseReductionMin
    end
    if luminanceNoiseReduction > luminanceNoiseReductionMax then
        luminanceNoiseReduction = luminanceNoiseReductionMax
    end

    local colorNoiseReduction = developSettings["ColorNoiseReduction"]  -- number
    if colorNoiseReduction < luminanceNoiseReduction then
        colorNoiseReduction = luminanceNoiseReduction
    end

    mylog(fileName .. ": ISO = " .. iso .. ", will set luminance NR = " .. luminanceNoiseReduction .. ", color NR = " .. colorNoiseReduction)

    local ret = setDevelopSettings(developSettings, "LuminanceSmoothing", luminanceNoiseReduction)
    changed = changed or ret
    ret = setDevelopSettings(developSettings, "ColorNoiseReduction", colorNoiseReduction)
    changed = changed or ret
    if changed then
        catalog:withWriteAccessDo(scriptName, function(context)
            photo:applyDevelopSettings(developSettings, scriptName, false)
        end )
    end
end


LrTasks.startAsyncTask(function()
    -- local photos = catalog:getTargetPhotos()
    local numSources = #activeSources
    mylog("MAIN" .. "Number of active sources (collections/folders): " .. numSources)
    -- local photos = folder:getPhotos{ includeChildren = true }

    if numSources > 1 then 
        mylog("MAIN" .. "No handling available yet for more than one active source. Action aborted." .. numSources)
        return -- TODO patch this
    end
    
    assert(numSources[1]:isKindOf("LrFolder"), "Expected first active source to be LrFolder, but it was instead a " .. numSources[1]:getType())

    local photos = numSources[1].getPhotos()
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