
# LR_AUTO_EXP='/Users/lynnettetee/Library/Application Support/Adobe/Lightroom/Scripts/lr_auto_exposure.lua'
LR_APP_NAME="Adobe Lightroom Classic"
# LR Menu details
TOP_LEVEL_MENU="Scripts"
SCRIPT_MENU_ITEM="lr_auto_exposure"

# launch Lightroom
open -a ${LR_APP_NAME}
TIMEOUT=60
INTERVAL=2
launched=false
for (( i=0; i<TIMEOUT; i+=INTERVAL )); do
    if osascript -e 'tell application "System Events" to count (windows of process "'"${LR_APP_NAME}"'") > 0' &>/dev/null; then
        launched=true
        break
    fi
    sleep "$INTERVAL"
done

if [ "$launched" = false ]; then
    echo "Error: ${LR_APP_NAME} did not launch or become ready within ${TIMEOUT} seconds."
    exit 1
fi

echo "${LR_APP_NAME} is ready."


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

echo "Command to run '${SCRIPT_MENU_ITEM}' script sent to ${LR_APP_NAME}."