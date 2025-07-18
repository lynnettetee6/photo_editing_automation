#!/bin/zsh

LOCKFILE="$DEST/.copy.lock"
MIN_JPG_SIZE=500000   # 500 KB
MIN_RAF_SIZE=20000000 # 20 MB
MIN_MOV_SIZE=2000000  # 2 MB
PROCESSED_FILE="$DEST/$PROCESSED_LOG_NAME"

echo "SRC: $SRC"
echo "DEST: $DEST"

# Ensure lock file is removed on script exit (even if interrupted)
trap 'rm -f "$LOCKFILE"; echo "Lock file removed (cleanup)."; exit' INT TERM

# Check for .lock file
if [[ -e $LOCKFILE ]]; then
  echo "🚫 Operation blocked. Media already in progress or completed."
  exit 0 
fi

echo "🔓 No lock found. Proceeding with media transfer..."

# Create lock file at destination directory
touch "$LOCKFILE"
echo "🔒 Lock file created at $LOCKFILE"

# Make sure SRC and DEST exist
if [[ ! -d "$SRC" || ! -d "$DEST" ]]; then
  echo "Either '$SRC' or '$DEST' does not exist."
  exit 1
fi

# Create processed log if it doesn't exist
if [[ ! -f "$PROCESSED_FILE" ]]; then
  touch "$PROCESSED_FILE"
  echo "📝 Created processed log at $PROCESSED_FILE"
fi

# Rollback corrupted files
echo "🔍 Checking for partially copied files in: $dir"

find "$DEST" \( \
  -iname "*.MOV" -size -${MIN_MOV_SIZE}c -o \
  -iname "*.RAF" -size -${MIN_RAF_SIZE}c -o \
  -iname "*.JPG" -size -${MIN_JPG_SIZE}c \
\) -print -exec rm -f {} \;

echo "✅ Cleanup complete."

# Loop through items in SRC
for file in "$SRC"/*; do
  # Check if it's a regular file (not directory, symlink, etc.)
  if [[ -f "$file" ]]; then
    filename=$(basename "$file")
    # Check if file is already processed
    if ! grep -q "^${filename}$" "$PROCESSED_FILE" && [[ ! -e "$DEST/$filename" ]]; then
      cp "$file" "$DEST/"
      echo "Copied $filename to $DEST"
    fi
  fi
done

# Get space usage information for SRC and DEST
space_in_SRC=$(df -h $SRC | awk 'NR==2 {print $3, $4}')
space_in_DEST=$(df -h $DEST | awk 'NR==2 {print $3, $4}')

# Output the space used and available in SRC and DEST
echo "Space used and available in '${SRC:h:h:t}': $space_in_SRC"
echo "Space used and available in '${DEST:h:t}': $space_in_DEST"

# Remove .lock file
rm $LOCKFILE
echo "✅ Transfer complete. Lock file removed."

# Optionally eject volume
#echo "Eject volumes '${SRC:h:h:t}' and '${DEST:h:t}'? (y/n)?"
#read eject
#if [[ $eject == [Yy] ]]; then  
#  echo "Ejecting volumes..."
#  diskutil eject ${SRC:h:h}
#  diskutil eject ${DEST:h}
#  echo "Ejected both volumes."
#else
#  echo "Ejection aborted."
#fi

