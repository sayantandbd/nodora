#!/bin/bash

require_root
log_header "Add New Project"

PROJ_NAME=${1:-default-app}
DOMAIN_NAME=${2:-default.local}
ENTRY_FILE=${3:-index.js}
PROJ_PORT=$4

if [ -z "$PROJ_PORT" ]; then
  PROJ_PORT=$(get_next_available_port)
fi

log_info "Using Project Name: $PROJ_NAME"
log_info "Using Domain Name: $DOMAIN_NAME"
log_info "Using Entry File: $ENTRY_FILE"
log_info "Using Internal Port: $PROJ_PORT"

PROJ_DIR="$BASE_DIR/$PROJ_NAME"
ECOSYSTEM_DIR="$BASE_DIR/ecosystems"

log_info "Creating project directory at $PROJ_DIR..."
mkdir -p "$PROJ_DIR"

log_info "Creating ecosystems directory at $ECOSYSTEM_DIR..."
mkdir -p "$ECOSYSTEM_DIR"

# Ecosystem config
ECOSYSTEM_FILE="$ECOSYSTEM_DIR/$PROJ_NAME.config.js"
if [ ! -f "$ECOSYSTEM_FILE" ]; then
  cat <<EOF > "$ECOSYSTEM_FILE"
module.exports = {
  apps: [
    {
      name: "$PROJ_NAME",
      script: "$ENTRY_FILE",
      cwd: "$PROJ_DIR",
      env: {
        NODE_ENV: "production",
        PORT: $PROJ_PORT
      },
      error_file: "$BASE_DIR/logs/$PROJ_NAME-err.log",
      out_file: "$BASE_DIR/logs/$PROJ_NAME-out.log"
    }
  ]
};
EOF
  log_info "Created PM2 config at $ECOSYSTEM_FILE"
else
  log_info "PM2 config already exists at $ECOSYSTEM_FILE"
fi

# Set ownership
chown -R nodora:nodora "$PROJ_DIR"
chown -R nodora:nodora "$ECOSYSTEM_DIR"

# Caddy setup
CADDY_FILE="/etc/caddy/Caddyfile.d/$DOMAIN_NAME.caddy"
log_info "Creating Caddy configuration at $CADDY_FILE..."
mkdir -p /etc/caddy/Caddyfile.d
cat <<EOF > "$CADDY_FILE"
$DOMAIN_NAME {
    reverse_proxy localhost:$PROJ_PORT
}
EOF

log_info "Reloading Caddy to apply changes..."
systemctl reload caddy || true

echo "========================================="
echo "  Project '$PROJ_NAME' added successfully!  "
echo "  Directory: $PROJ_DIR"
echo "  Domain: $DOMAIN_NAME (proxied to port $PROJ_PORT)"
echo "  Entry File: $ENTRY_FILE"
echo "  "
echo "  Next steps:"
echo "  1. Add your code to $PROJ_DIR (e.g. git clone <repo> .)"
echo "  2. Start PM2: sudo -u nodora pm2 start $ECOSYSTEM_FILE && sudo -u nodora pm2 save"
echo "========================================="
