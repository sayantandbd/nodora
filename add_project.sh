#!/bin/bash
# add_project.sh (Nodora CLI)

set -e

NODORA_VERSION="1.0.0"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

BASE_DIR="/var/www/projects"

show_help() {
  echo "Nodora CLI v$NODORA_VERSION"
  echo "========================================="
  echo "Usage: nodora <command> [options]"
  echo ""
  echo "Commands:"
  echo "  add <project> <domain> <port>   Add a new Node.js project"
  echo "  list                            List running servers and project directories"
  echo "  restart                         Restart all PM2 apps and Caddy server"
  echo "  update                          Update Nodora CLI to the latest version"
  echo "  -v, --version                   Show version"
  echo "  help                            Show this help message"
  echo "========================================="
}

COMMAND=$1

case "$COMMAND" in
  -v|--version)
    echo "Nodora version $NODORA_VERSION"
    ;;
  
  list)
    echo "========================================="
    echo "  Nodora: Server List  "
    echo "========================================="
    echo "--- PM2 Apps ---"
    pm2 list || echo "PM2 is not running or no apps found."
    echo ""
    echo "--- Project Directories (/var/www/projects) ---"
    ls -l $BASE_DIR | grep "^d" | awk '{print $9}' || echo "No projects found."
    ;;

  restart)
    echo "========================================="
    echo "  Nodora: Restarting Servers  "
    echo "========================================="
    echo "Restarting PM2 apps..."
    pm2 restart all || echo "No PM2 apps to restart."
    echo "Restarting Caddy web server..."
    systemctl restart caddy || echo "Failed to restart Caddy."
    echo "Restart complete!"
    ;;

  update)
    echo "========================================="
    echo "  Nodora: Updating CLI  "
    echo "========================================="
    echo "Fetching the latest version from GitHub..."
    curl -sL https://raw.githubusercontent.com/sayantandbd/nodora/main/add_project.sh -o /usr/local/bin/nodora
    chmod +x /usr/local/bin/nodora
    echo "Nodora CLI updated successfully!"
    ;;

  add)
    echo "========================================="
    echo "  Nodora: Add New Project  "
    echo "========================================="

    # Shift past the 'add' command
    shift

    PROJ_NAME=${1:-default-app}
    DOMAIN_NAME=${2:-default.local}
    PROJ_PORT=${3:-3000}

    echo "Using Project Name: $PROJ_NAME"
    echo "Using Domain Name: $DOMAIN_NAME"
    echo "Using Internal Port: $PROJ_PORT"

    PROJ_DIR="$BASE_DIR/$PROJ_NAME"

    echo "Creating project directory at $PROJ_DIR..."
    mkdir -p "$PROJ_DIR"

    # Basic ecosystem.config.js
    ECOSYSTEM_FILE="$PROJ_DIR/ecosystem.config.js"
    if [ ! -f "$ECOSYSTEM_FILE" ]; then
      cat <<EOF > "$ECOSYSTEM_FILE"
module.exports = {
  apps: [
    {
      name: "$PROJ_NAME",
      script: "index.js", // Update this to your entry file
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
      echo "Created PM2 ecosystem.config.js"
    else
      echo "PM2 ecosystem.config.js already exists."
    fi

    # Caddy setup
    CADDY_FILE="/etc/caddy/Caddyfile.d/$DOMAIN_NAME.caddy"
    echo "Creating Caddy configuration at $CADDY_FILE..."
    mkdir -p /etc/caddy/Caddyfile.d
    cat <<EOF > "$CADDY_FILE"
$DOMAIN_NAME {
    reverse_proxy localhost:$PROJ_PORT
}
EOF

    echo "Reloading Caddy to apply changes..."
    systemctl reload caddy || true

    echo "========================================="
    echo "  Project '$PROJ_NAME' added successfully!  "
    echo "  Directory: $PROJ_DIR"
    echo "  Domain: $DOMAIN_NAME (proxied to port $PROJ_PORT)"
    echo "  "
    echo "  Next steps:"
    echo "  1. Add your code to $PROJ_DIR"
    echo "  2. Start PM2: cd $PROJ_DIR && pm2 start ecosystem.config.js && pm2 save"
    echo "========================================="
    ;;
  
  *)
    show_help
    ;;
esac
