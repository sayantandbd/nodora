#!/bin/bash

require_root() {
  if [ "$EUID" -ne 0 ]; then
    log_error "Please run this command as root or using sudo."
    exit 1
  fi
}

get_next_available_port() {
  local highest_port=$(grep -oP 'localhost:\K\d+' /etc/caddy/Caddyfile.d/*.caddy 2>/dev/null | sort -n | tail -n 1 || echo "")
  if [ -z "$highest_port" ]; then
    echo 3000
  else
    echo $((highest_port + 1))
  fi
}
