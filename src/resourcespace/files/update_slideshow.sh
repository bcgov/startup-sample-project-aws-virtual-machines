#!/bin/bash

# Find all slideshow directories, print modification time and path
# Then sort them by modification time, oldest first
readarray -t directories < <(find /opt/bitnami/resourcespace/filestore/system/ -type d -name "slideshow_*" -printf '%T+ %p\n' | sort | cut -d' ' -f2-)

# The first element in the sorted array is the oldest directory
keep_directory="${directories[0]}"
echo "Keeping oldest slideshow dir: $keep_directory"
directory_name=$(basename "$keep_directory")

# Update the config.php with the oldest directory
sudo sed -i "s|'filestore/system/slideshow_[^']*'|'filestore/system/$directory_name'|" /opt/bitnami/resourcespace/include/config.php
echo "Slideshow directory in config.php updated to filestore/system/$directory_name"

# Remove all other slideshow directories
for dir in "${directories[@]}"; do
    if [[ "$dir" != "$keep_directory" ]]; then
        echo "Removing extra slideshow dir: $dir"
        sudo rm -rf "$dir"
    fi
done