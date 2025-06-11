return {
    LrPluginName = LOC "$$$/AutoExposureImport/PluginName=Auto Exposure",
    LrToolkitIdentifier = "com.lynnettetee.autoexposure",
    LrSdkVersion = 14.0,
    LrSdkMinimumVersion = 6.0,

    LrLibraryMenuItems = {
        {
            title = "Auto Exposureeee",
            file = "AutoExposureTask.lua",
            -- enabledWhen = "photosAvailable",
            functionToRun = "applyAutoExposureAndResetOthersToAll"
        }
    }
}
