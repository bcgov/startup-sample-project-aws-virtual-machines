#!/bin/bash
# Find the slideshow directory and update the config.php file
DIRECTORY=$(find /opt/bitnami/resourcespace/filestore/system/ -type d -name "slideshow*" -print -quit)
echo Updating slideshow dir to $DIRECTORY
DIRECTORY_NAME=$(basename "$DIRECTORY")
sudo sed -i "s|'filestore/system/slideshow_[^']*'|'filestore/system/$DIRECTORY_NAME'|" /opt/bitnami/resourcespace/include/config.php
echo Slideshow directory in config.php updated