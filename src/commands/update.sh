#!/bin/bash

require_root
log_header "Updating CLI"

log_info "Fetching the latest version from GitHub..."

if [ -d "/opt/nodora/.git" ]; then
  cd /opt/nodora
  git pull origin main
  log_info "Nodora CLI updated successfully!"
else
  log_error "/opt/nodora is not a git repository. Cannot update automatically."
  exit 1
fi
