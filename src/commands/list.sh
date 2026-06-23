#!/bin/bash

require_root
log_header "Server List"

TARGET_USER=${SUDO_USER:-root}
echo "--- PM2 Apps ---"
sudo -u $TARGET_USER pm2 list || echo "PM2 is not running or no apps found."
echo ""
echo "--- Project Directories ($BASE_DIR) ---"
ls -l $BASE_DIR | grep "^d" | awk '{print $9}' || echo "No projects found."
