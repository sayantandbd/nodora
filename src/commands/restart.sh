#!/bin/bash

require_root
log_header "Restarting Servers"

TARGET_USER=${SUDO_USER:-root}
log_info "Restarting PM2 apps..."
sudo -u $TARGET_USER pm2 restart all || log_info "No PM2 apps to restart."

log_info "Restarting Caddy web server..."
systemctl restart caddy || log_error "Failed to restart Caddy."

log_info "Restart complete!"
