#!/bin/zsh

# LR_AUTO_EXP='/Users/lynnettetee/Library/Application Support/Adobe/Lightroom/Scripts/lr_auto_exposure.lua'
APP_NAME="Adobe Lightroom Classic"
# LR Menu details
TOP_LEVEL_MENU="Scripts"
SCRIPT_MENU_ITEM="lr_auto_exposure"

# launch Lightroom
open -a ${APP_NAME}

# poll to see if app menu bar is ready
MAIN_APP_WINDOW_TITLE='Lightroom Catalog-v12.lrcat - Adobe Photoshop Lightroom Classic - Library' # the EXACT title name
MAIN_CONTENT_ELEMENT_CHECK='exists (static texts of window "'"${MAIN_APP_WINDOW_TITLE}"'" whose value is "Quick Develop" and visible is true)'
INITIAL_PROCESS_TIMEOUT=30 
MENU_READY_TIMEOUT=90 
FINAL_READY_TIMEOUT=120
INTERVAL=2 
launched=false
LR_BUNDLE_ID=$(osascript -e "id of app \"${APP_NAME}\"" 2>/dev/null)
# NEW: Specific UI element check for the "Quick Develop" text.


if [[ -z "$LR_BUNDLE_ID" ]]; then
    echo "Error: Could not find Bundle ID for '${APP_NAME}'. Is the app installed correctly?"
    echo "Please ensure '${APP_NAME}.app' exists in your /Applications folder."
    exit 1
fi

# wait for app to launch
echo "Waiting for ${APP_NAME} process to start (max ${INITIAL_PROCESS_TIMEOUT}s)..."
is_app_running=false
for (( i=0; i<INITIAL_PROCESS_TIMEOUT; i+=INTERVAL )); do
    # 'tell application id "..." to get running' returns 'true' or 'false' directly
    if osascript -e 'tell application id "'"${LR_BUNDLE_ID}"'" to get running' &>/dev/null; then
        is_app_running=true
        echo "  - Process '${APP_NAME}' is now running."
        break
    else
        echo "  - Still waiting for '${APP_NAME}' process to appear..."
    fi
    sleep "$INTERVAL"
done

if [ "$is_app_running" = false ]; then
    echo "Error: ${APP_NAME} process did not start within ${INITIAL_PROCESS_TIMEOUT} seconds."
    exit 1
fi

# Poll to see if the specific menu item exists (indicates UI is fully launched and functional) ---
echo "Waiting for '${TOP_LEVEL_MENU}' menu item in ${APP_NAME} to become available (max ${MENU_READY_TIMEOUT}s)..."
is_menu_ready=false
for (( i=0; i<MENU_READY_TIMEOUT; i+=INTERVAL )); do
    # Check for the existence of the specific menu bar item.
    # This requires Accessibility permissions for your Terminal/IDE.
    if osascript -e 'tell application "System Events" to exists menu bar item "'"${TOP_LEVEL_MENU}"'" of menu bar 1 of process "'"${APP_NAME}"'"' &>/dev/null; then
        is_menu_ready=true
        echo "  - Menu item '${TOP_LEVEL_MENU}' detected. App is likely fully launched and ready."
        break
    else
        echo "  - Still waiting for '${TOP_LEVEL_MENU}' menu item to become available..."
    fi
    sleep "$INTERVAL"
done

if [ "$is_menu_ready" = false ]; then
    echo "Error: '${TOP_LEVEL_MENU}' menu item in ${APP_NAME} did not become ready within ${MENU_READY_TIMEOUT} seconds."
    echo "This might indicate a problem with the app's launch, or insufficient Accessibility permissions for your terminal."
    exit 1
fi


# Poll for the main application window title 
echo "Waiting for main window '${MAIN_APP_WINDOW_TITLE}' to appear and be visible (max ${FINAL_READY_TIMEOUT}s)..."
is_fully_launched=false
for (( i=0; i<FINAL_READY_TIMEOUT; i+=INTERVAL )); do
    if osascript -e 'tell application "System Events" to (exists (windows of process "'"${APP_NAME}"'" whose name contains "'"${MAIN_APP_WINDOW_TITLE}"'" and visible is true))' &>/dev/null; then
        is_fully_launched=true
        echo "  - Main window '${MAIN_APP_WINDOW_TITLE}' detected and visible. App is fully launched!"
        break
    fi
    echo "  - Still waiting for main window '${MAIN_APP_WINDOW_TITLE}' to become visible..."
    sleep "$INTERVAL"
done

if [ "$is_fully_launched" = false ]; then
    echo "Error: Main window for ${APP_NAME} did not appear or become visible within ${FINAL_READY_TIMEOUT} seconds."
    echo "This might mean the app is stuck launching, or the window title is incorrect."
    exit 1
fi


# Poll for the "Quick Develop" text element (THE FINAL "DONE LAUNCHING" CHECK) ---
echo "Waiting for 'Quick Develop' text to appear and be visible (max ${FINAL_CONTENT_LOAD_TIMEOUT}s)..."
is_fully_launched=false
for (( i=0; i<FINAL_CONTENT_LOAD_TIMEOUT; i+=INTERVAL )); do
    if osascript -e '
        tell application "System Events"
            tell process "'"${APP_NAME}"'"
                # First ensure the main window we target exists
                if exists window "'"${MAIN_APP_WINDOW_TITLE}"'" then
                    tell window "'"${MAIN_APP_WINDOW_TITLE}"'"
                        -- Use the MAIN_CONTENT_ELEMENT_CHECK variable from above
                        if '"${MAIN_CONTENT_ELEMENT_CHECK}"' then
                            return true
                        end if
                    end tell
                end if
            end tell
            return false
        end tell
    ' &>/dev/null; then
        is_fully_launched=true
        echo "  - 'Quick Develop' text detected. App is fully launched!"
        break
    fi
    echo "  - Still waiting for 'Quick Develop' text to become visible..."
    sleep "$INTERVAL"
done

if [ "$is_fully_launched" = false ]; then
    echo "Error: 'Quick Develop' text for ${APP_NAME} did not appear or become visible within ${FINAL_CONTENT_LOAD_TIMEOUT} seconds."
    echo "This might mean the app is stuck launching, or the Accessibility Inspector details for 'Quick Develop' are incorrect."
    exit 1
fi

echo "--- ${APP_NAME} is fully launched and ready! ---"


echo "Attempting to run script '${SCRIPT_MENU_ITEM}' in ${APP_NAME} via menu bar..."

# --- AppleScript to click the menu item ---
osascript -e '
    -- Set variables for the AppleScript part
    set appName to "'"${APP_NAME}"'"
    set topLevelMenu to "'"${TOP_LEVEL_MENU}"'"
    set scriptMenuItem to "'"${SCRIPT_MENU_ITEM}"'"

    tell application "System Events"
        -- Check if the application process is running
        set isRunning to false
        try
            set isRunning to (exists process appName)
        end try

        if isRunning then
            tell process appName
                -- Bring the application to the front (crucial for menu interaction)
                set frontmost to true
                delay 0.5 -- Give it a moment to become frontmost

                -- Access the menu bar and click the specific item
                tell menu bar 1
                    tell menu bar item topLevelMenu
                        tell menu topLevelMenu
                            click menu item scriptMenuItem
                            log "Successfully clicked '" & scriptMenuItem & "' menu item in '" & topLevelMenu & "' menu."
                        end tell
                    end tell
                end tell
            end tell
            log "Command sent to " & appName & "."
        else
            log "Error: Application '" & appName & "' is not running."
            display dialog "Error: " & appName & " is not running. Please launch it first." buttons {"OK"} default button "OK" with icon caution
            error number -128 -- Standard AppleScript error for user cancellation/aborted script
        end if
    end tell
'

echo "Command to run '${SCRIPT_MENU_ITEM}' script sent to ${APP_NAME}."