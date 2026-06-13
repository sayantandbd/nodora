#!/bin/bash
# install.sh

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

echo "========================================="
echo "  Nodora Setup Wizard  "
echo "========================================="

# 1. OS Check
if ! grep -q "Ubuntu" /etc/os-release; then
  echo "Error: This script is only supported on Ubuntu."
  exit 1
fi

echo "Ubuntu detected. Proceeding..."

# 2. Setup Variables
SWAP_SIZE=${1:-4}
echo "Using swap size: ${SWAP_SIZE}GB"

BASE_DIR="/var/www/projects"
echo "Projects will be stored in: $BASE_DIR"

# 3. Swap Setup
if swapon --show | grep -q "/swapfile"; then
  echo "Swap file already exists. Skipping swap creation."
else
  echo "Creating ${SWAP_SIZE}GB swap file..."
  fallocate -l ${SWAP_SIZE}G /swapfile || dd if=/dev/zero of=/swapfile bs=1G count=${SWAP_SIZE}
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
  fi
  echo "Swap configured successfully."
fi

# 4. Update and Dependencies
echo "Updating system packages..."
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git jq software-properties-common apt-transport-https debian-keyring debian-archive-keyring

# Node.js (Latest LTS)
if ! command -v node &> /dev/null; then
  echo "Installing Node.js (Latest LTS)..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt-get install -y nodejs
  npm install -g npm@latest
else
  echo "Node.js is already installed. Skipping..."
fi

# PM2
if ! command -v pm2 &> /dev/null; then
  echo "Installing PM2..."
  npm install -g pm2
else
  echo "PM2 is already installed. Skipping..."
fi

# GitLab Runner
if ! command -v gitlab-runner &> /dev/null; then
  echo "Installing GitLab Runner..."
  curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
  apt-get install -y gitlab-runner
else
  echo "GitLab Runner is already installed. Skipping..."
fi

# Caddy
if ! command -v caddy &> /dev/null; then
  echo "Installing Caddy..."
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
  apt-get update
  apt-get install -y caddy
else
  echo "Caddy is already installed. Skipping..."
fi

# 5. Directory Setup
echo "Setting up base directories..."
mkdir -p "$BASE_DIR"
mkdir -p "$BASE_DIR/logs"

# 6. Caddy Config & Default Site
echo "Creating default HTML page..."
mkdir -p /var/www/html
cat <<'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Nodora</title>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; text-align: center; padding: 50px; background: #f4f4f9; color: #333; }
        .container { max-width: 600px; margin: auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        code { background: #eee; padding: 2px 6px; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Nodora! 🚀</h1>
        <p>Your server has been provisioned successfully.</p>
        <p>Use the <code>nodora</code> command to add new projects.</p>
    </div>
</body>
</html>
EOF

echo "Configuring Caddy..."
mkdir -p /etc/caddy/Caddyfile.d
if ! grep -q "import /etc/caddy/Caddyfile.d/\*.caddy" /etc/caddy/Caddyfile; then
  echo "import /etc/caddy/Caddyfile.d/*.caddy" >> /etc/caddy/Caddyfile
fi

cat <<'EOF' > /etc/caddy/Caddyfile.d/default.caddy
:80 {
    root * /var/www/html
    file_server
}
EOF

systemctl reload caddy || true # Might fail if Caddy isn't fully started yet

# 7. Install Nodora CLI
if [ -f "./add_project.sh" ]; then
  echo "Installing nodora CLI from local file..."
  cp ./add_project.sh /usr/local/bin/nodora
  chmod +x /usr/local/bin/nodora
  echo "Nodora CLI installed successfully."
else
  echo "Downloading nodora CLI from GitHub..."
  curl -sL https://raw.githubusercontent.com/sayantandbd/nodora/main/add_project.sh -o /usr/local/bin/nodora
  chmod +x /usr/local/bin/nodora
  echo "Nodora CLI installed successfully."
fi

# 8. Documentation Output
INSTALL_TXT="$BASE_DIR/installation.txt"
echo "Generating installation documentation at $INSTALL_TXT..."

cat <<EOF > "$INSTALL_TXT"
Nodora Installation Details
===========================
Base Directory: $BASE_DIR
Logs Directory: $BASE_DIR/logs
Swap Size: ${SWAP_SIZE}GB

Installed Versions:
- Node.js: \$(node -v)
- npm: \$(npm -v)
- PM2: \$(pm2 -v)
- Caddy: \$(caddy version)
- GitLab Runner: \$(gitlab-runner --version | head -n 1)

Getting Started & First Login:
1. Access your server: ssh root@<your-server-ip>
2. Add a new project by running: nodora add <project_name> <domain> <port>
3. Your default web page is live at: http://<your-server-ip>/

GitLab Runner Registration:
To register a runner, run: sudo gitlab-runner register
EOF

echo "========================================="
echo "  Setup Complete!  "
echo "========================================="
cat "$INSTALL_TXT"
echo "========================================="
