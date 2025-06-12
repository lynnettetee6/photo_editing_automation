#!/bin/zsh

# --- Configuration ---
LR_APP_PROCESS_NAME="Adobe Lightroom Classic" # UPDATE THIS IF NEEDED

# Menu path details (still useful, but not the final check)
TOP_LEVEL_MENU_TO_CHECK="Scripts"

# The expected PARTIAL title of Lightroom's main window when it's fully launched.
# This will be used with 'contains' for flexibility (e.g., if catalog name varies).
# *** YOU MUST VERIFY THIS PARTIAL TITLE EXACTLY ***
# Examples: "Adobe Lightroom Classic", "Lightroom Classic"
MAIN_APP_WINDOW_TITLE_PARTIAL="Lightroom Catalog-v12.lrcat - Adobe Photoshop Lightroom Classic - Library" # the EXACT title name" 

# NEW: Specific UI element check for the "Quick Develop" text.
# *** THIS NOW ONLY DEFINES THE ELEMENT PROPERTIES, NOT THE WINDOW ***
# It means: "a static text element whose value is 'Quick Develop' and is visible"
MAIN_CONTENT_ELEMENT_CHECK='static texts whose value is "Quick Develop" and visible is true'
# If Accessibility Inspector showed 'Class/Role: AXTextField' for "Quick Develop":
# MAIN_CONTENT_ELEMENT_CHECK='text fields whose value is "Quick Develop" and visible is true'


# Timeouts and intervals
INITIAL_PROCESS_TIMEOUT=30
UI_READY_TIMEOUT=90
FINAL_CONTENT_LOAD_TIMEOUT=180 # Increased timeout for content loading
INTERVAL=2

echo "--- Starting Lightroom Launch Script ---"

# --- 1. Get the Bundle ID for the application ---
echo "Determining Bundle ID for '${LR_APP_PROCESS_NAME}'..."
LR_BUNDLE_ID=$(osascript -e "id of app \"${LR_APP_PROCESS_NAME}\"" 2>/dev/null)

if [[ -z "$LR_BUNDLE_ID" ]]; then
    echo "Error: Could not find Bundle ID for '${LR_APP_PROCESS_NAME}'. Is the app installed correctly?"
    echo "Please ensure '${LR_APP_PROCESS_NAME}.app' exists in your /Applications folder."
    exit 1
fi
echo "Identified Bundle ID: ${LR_BUNDLE_ID}"

# --- 2. Launch the application ---
echo "Launching ${LR_APP_PROCESS_NAME}..."
open -a "${LR_APP_PROCESS_NAME}"

# --- 3. Poll to see if the app process is running (using Bundle ID) ---
echo "Waiting for ${LR_APP_PROCESS_NAME} process to start (max ${INITIAL_PROCESS_TIMEOUT}s)..."
is_app_running=false
for (( i=0; i<INITIAL_PROCESS_TIMEOUT; i+=INTERVAL )); do
    if osascript -e 'tell application id "'"${LR_BUNDLE_ID}"'" to get running' &>/dev/null; then
        is_app_running=true
        echo "  - Process '${LR_APP_PROCESS_NAME}' is now running."
        break
    fi
    echo "  - Still waiting for '${LR_APP_PROCESS_NAME}' process to appear..."
    sleep "$INTERVAL"
done

if [ "$is_app_running" = false ]; then
    echo "Error: ${LR_APP_PROCESS_NAME} process did not start within ${INITIAL_PROCESS_TIMEOUT} seconds."
    exit 1
fi

# --- 4. Poll to see if the specific menu item exists (first UI readiness check) ---
echo "Waiting for '${TOP_LEVEL_MENU_TO_CHECK}' menu item in ${LR_APP_PROCESS_NAME} to become available (max ${UI_READY_TIMEOUT}s)..."
is_menu_item_ready=false
for (( i=0; i<UI_READY_TIMEOUT; i+=INTERVAL )); do
    if osascript -e 'tell application "System Events" to exists menu bar item "'"${TOP_LEVEL_MENU_TO_CHECK}"'" of menu bar 1 of process "'"${LR_APP_PROCESS_NAME}"'"' &>/dev/null; then
        is_menu_item_ready=true
        echo "  - Menu item '${TOP_LEVEL_MENU_TO_CHECK}' detected."
        break
    fi
    echo "  - Still waiting for '${TOP_LEVEL_MENU_TO_CHECK}' menu item to become available..."
    sleep "$INTERVAL"
done

if [ "$is_menu_item_ready" = false ]; then
    echo "Error: '${TOP_LEVEL_MENU_TO_CHECK}' menu item in ${LR_APP_PROCESS_NAME} did not become ready within ${UI_READY_TIMEOUT} seconds."
    echo "This might indicate a problem with the app's launch, or insufficient Accessibility permissions for your terminal."
    exit 1
fi

# --- 5. Poll for the "Quick Develop" text element (THE FINAL "DONE LAUNCHING" CHECK) ---
echo "Waiting for 'Quick Develop' text to appear and be visible (max ${FINAL_CONTENT_LOAD_TIMEOUT}s)..."
is_fully_launched=false
for (( i=0; i<FINAL_CONTENT_LOAD_TIMEOUT; i+=INTERVAL )); do
    # Corrected AppleScript to avoid double window reference
    if osascript -e '
        set processName to "'"${LR_APP_PROCESS_NAME}"'"
        set windowTitlePartial to "'"${MAIN_APP_WINDOW_TITLE_PARTIAL}"'"
        set elementCheck to "'"${MAIN_CONTENT_ELEMENT_CHECK}"'" # This is the string for the internal check

        tell application "System Events"
            tell process processName
                # Find the main window whose name contains the partial title
                set main_windows to (windows whose name contains windowTitlePartial and visible is true)
                
                if (count of main_windows) > 0 then
                    # We found at least one potential main window.
                    # Now, check for the content element within the first one (or iterate if multiple)
                    # The 'elementCheck' is run within the context of 'tell main_windows item 1'
                    if exists (elements of (main_windows item 1) whose ('"$(echo "${MAIN_CONTENT_ELEMENT_CHECK}" | sed "s/^exists (//; s/)$//")"' )) then
                        return true
                    end if
                end if
            end tell
            return false # Return false if no such element was found in any matching window
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
    echo "Error: 'Quick Develop' text for ${LR_APP_PROCESS_NAME} did not appear or become visible within ${FINAL_CONTENT_LOAD_TIMEOUT} seconds."
    echo "This might mean the app is stuck launching, or the Accessibility Inspector details for 'Quick Develop' are incorrect."
    exit 1
fi

echo "--- ${LR_APP_PROCESS_NAME} is fully launched and ready! ---"