# Nodora

Nodora is an automated shell scripting tool to instantly provision a production-ready Node.js environment on an Ubuntu server. It automatically configures Caddy as a reverse proxy, PM2 for process management, sets up a default landing page, and prepares GitLab Runner for CI/CD.

## Tech Stacks / Server Stacks
- **OS**: Ubuntu Linux
- **Web Server / Reverse Proxy**: [Caddy](https://caddyserver.com/) (Auto HTTPS)
- **Runtime**: Node.js (Latest LTS)
- **Process Manager**: PM2
- **CI/CD**: GitLab Runner

## Prerequisites
- A freshly provisioned server running Ubuntu.
- Root or `sudo` privileges.

## Getting Started

You can install Nodora directly via `curl`. By default, this sets up a 4GB swap file.

### Direct Installation (Recommended)

Run the following command to download and execute the installation script in one step:

```bash
curl -sL https://raw.githubusercontent.com/sayantandbd/nodora/main/install.sh | sudo bash
```

*Note: You can pass a custom swap size (in GB) as an argument. For example, to set a 2GB swap size:*
```bash
curl -sL https://raw.githubusercontent.com/sayantandbd/nodora/main/install.sh | sudo bash -s -- 2
```

## Cloud Provider Setup (User Data / Cloud-Init)

To automatically ready your containers or VMs upon boot in AWS, DigitalOcean, or other cloud providers, add the following script to your instance's **User Data** section:

```bash
#!/bin/bash
# Install Nodora with default 4GB swap
curl -sL https://raw.githubusercontent.com/sayantandbd/nodora/main/install.sh | bash

# Optionally, auto-add your first project
# nodora <project_name> <domain> <port>
nodora default-app default.local 3000
```

## Adding a New Project

The installation automatically installs the `nodora` CLI globally. You can easily add new Node.js apps and route domains without manual configuration.

Run the `nodora` command with your project details:

```bash
sudo nodora <project_name> <domain_name> <internal_port>
```

**Example:**
```bash
sudo nodora my-api api.example.com 3000
```

*If you run `nodora` without arguments, it will use defaults (`default-app`, `default.local`, `3000`).*

When executed, Nodora will:
1. Create a project folder at `/var/www/projects/<project_name>`.
2. Generate an `ecosystem.config.js` for PM2.
3. Automatically configure Caddy and reload the web server to start routing traffic to your app.

## GitLab Runner CI/CD Integration

Nodora pre-installs GitLab Runner. To set up CI/CD deployments for a specific project, follow these beginner-friendly steps:

1. **Get your Registration Token:**
   - Go to your project repository on GitLab.
   - Navigate to **Settings** > **CI/CD** > **Runners**.
   - Under "Specific runners", disable shared runners and copy the registration token.

2. **Register the Runner on your server:**
   Run the following command on your server:
   ```bash
   sudo gitlab-runner register
   ```
   * **Enter the GitLab instance URL:** (e.g., `https://gitlab.com/`)
   * **Enter the registration token:** (Paste the token you copied)
   * **Enter a description:** (e.g., `my-api-runner`)
   * **Enter tags:** (e.g., `node, production`)
   * **Enter an executor:** Type `shell` (this allows the runner to run PM2 and `npm` commands directly on your server).

3. **Add `.gitlab-ci.yml` to your project:**
   In the root of your Node.js project repository, create a `.gitlab-ci.yml` file to automate deployment. Example:

   ```yaml
   stages:
     - deploy

   deploy_production:
     stage: deploy
     tags:
       - node # Must match the tag you provided during registration
     script:
       - cd /var/www/projects/my-api
       - git pull origin main
       - npm install
       - pm2 restart ecosystem.config.js
     only:
       - main
   ```
   Now, every time you push to the `main` branch, your app will automatically pull the latest code, install dependencies, and restart PM2!

## File Structure

- `/var/www/projects`: Default base directory for all projects.
- `/var/www/projects/logs`: Centralized directory for PM2 out/error logs.
- `/etc/caddy/Caddyfile.d/*.caddy`: Individual Caddy configuration files for each domain.
- `/var/www/html/index.html`: Default landing page when accessed via IP.
- `/var/www/projects/installation.txt`: A reference file created during installation containing your setup details and login info.
