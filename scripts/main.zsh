#!/bin/zsh

ROOT_DIR='/Users/lynnettetee/Documents/ml_projects/photo_edit_automation'
TRANSFER='scripts/transfer.zsh'
SORT='sort/main.py'
CAT='categorize/main.py'
PY_VENV='/usr/local/Caskroom/miniconda/base/envs/photo-editing/bin/python'
LAUNCH='scripts/launch.zsh'

# transfer files to dest directory upon inserting SD card
${ROOT_DIR}/${TRANSFER}

# sort files into edit/ and rm/ based on image quality and file type
${PY_VENV} ${ROOT_DIR}/${SORT}

# launch Lightroom
open -a "Adobe Lightroom Classic"

# Apply Auto Exposure in Lightroom
${ROOT_DIR}/${LAUNCH}

# TODO tag photos by subject/theme
#./${ROOT_DIR}/tagging.py


