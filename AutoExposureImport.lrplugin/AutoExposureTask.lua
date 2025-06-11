local LrApplication = import 'LrApplication'
local LrDevelopController = import 'LrDevelopController'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'

-- Setup logger
local logger = LrLogger('AutoExposureLogger')
logger:enable('logfile')  -- Writes to plugin log file
-- function MyHWLibraryItem.outputToLog( message )
--     logger:trace( message )
-- end
-- MyHWLibraryItem.outputToLog( "props.myObservedString has been updated." )
-- MyHWLibraryItem.outputToLog( "Update button clicked." )


local function applyAutoExposureAndResetOthersToAll()
    logger:trace("Starting AutoExposure process...")

    local catalog = LrApplication.activeCatalog()
    local allPhotos = catalog:getAllPhotos()

    logger:trace("Total photos found in catalog: " .. #allPhotos)

    if #allPhotos == 0 then
        LrDialogs.message("No photos", "Catalog has no photos.", "info")
        logger:warn("No photos in catalog.")
        return
    end

    catalog:withWriteAccessDo("Auto Exposure and Reset Others", function()
        for i, photo in ipairs(allPhotos) do
            local fileName = photo:getFormattedMetadata("fileName") or "Unknown"
            logger:trace(string.format("[%d] Processing photo: %s", i, fileName))

            -- Try applying Auto Exposure
            local success, err = pcall(function()
                LrDevelopController.setSelectedPhotos({ photo })
                LrDevelopController.autoTone()
                logger:trace("Auto tone applied to: " .. fileName)
            end)

            if not success then
                logger:trace("Failed to apply auto tone to " .. fileName .. ": " .. tostring(err))
            end

            -- Reset specific develop settings
            local resetSettings = {
                contrast = 0,
                highlights = 0,
                shadows = 0,
                whites = 0,
                blacks = 0,
                texture = 0,
                clarity = 0,
                dehaze = 0,
                vibrance = 0,
                saturation = 0,
            }

            local resetSuccess, resetErr = pcall(function()
                photo:applyDevelopSettings(resetSettings)
                logger:trace("Reset develop settings for: " .. fileName)
            end)

            if not resetSuccess then
                logger:trace("Failed to reset settings for " .. fileName .. ": " .. tostring(resetErr))
            end
        end
    end)

    LrDialogs.message("Done", "Auto Exposure and reset applied to all photos.", "info")
    logger:trace("AutoExposure task completed.")
end

return {
    applyAutoExposureAndResetOthersToAll = applyAutoExposureAndResetOthersToAll
}
