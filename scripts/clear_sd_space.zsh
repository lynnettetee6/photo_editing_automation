#!/bin/zsh

# Define the directory and the comparison date (YYYY-MM-DD format)
dir="/Volumes/Untitled/DCIM/100_FUJI"  # Path to the directory
echo "Delete media before date (YYYY-MM-DD):"
read comparison_date # Date to compare (format: YYYY-MM-DD)

# Ensure the directory exists
if [[ ! -d "$dir" ]]; then
  echo "Directory $dir does not exist."
  exit 1
fi

# Convert the comparison date to a timestamp for easy comparison
comparison_timestamp=$(date -j -f "%Y-%m-%d" "$comparison_date" "+%s")

# Loop through each file in the directory
for file in "$dir"/*; do
  # Check if it is a regular file (not a directory)
  if [[ -f "$file" ]]; then
    # Get the file's creation timestamp
    file_create_timestamp=$(stat -f "%B" "$file")

    # Compare the creation date with the specified comparison date
    if [[ "$file_create_timestamp" -lt "$comparison_timestamp" ]]; then
      # If the file is older, delete it
      echo "Deleting $file (created on $(date -r "$file" "+%Y-%m-%d"))"
      rm "$file"
    fi
  fi
done

# Output space details
echo "Space used and left in ${dir:h:h:t}: $(df -h ${dir} | awk 'NR==2 {print $3, $4}')"
