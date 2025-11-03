#!/bin/bash
# OpenWebUI + llama.cpp Auto-Setup Script
# For Proxmox Docker VMs
set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Install dependencies
apt-get update
apt-get install -y curl whiptail ca-certificates gnupg lsb-release

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker's APT repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose v2 (update and install in one step)
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
systemctl enable --now docker

# Create directories
mkdir -p /opt/openwebui/{models,data}

# TUI Configuration
whiptail --title "OpenWebUI + llama.cpp Setup" --msgbox "This script will configure OpenWebUI with llama.cpp in high-availability mode with full privileges." 10 60

# Model selection
MODEL_URL=$(whiptail --title "Model Selection" --inputbox "Enter GGUF model URL (leave empty for default Mistral):" 10 60 "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf" 3>&1 1>&2 2>&3)

# Secret key generation
SECRET_KEY=$(openssl rand -hex 32)
whiptail --title "Secret Key" --msgbox "Generated secret key: $SECRET_KEY\n\nSave this securely!" 10 60

# Port configuration
WEBUI_PORT=$(whiptail --title "Port Configuration" --inputbox "Enter OpenWebUI port (default 3000):" 10 60 3000 3>&1 1>&2 2>&3)

# GPU acceleration
if whiptail --title "GPU Acceleration" --yesno "Enable GPU acceleration? (NVIDIA only)" 10 60; then
    GPU_CONFIG=" deploy:\n resources:\n reservations:\n devices:\n - driver: nvidia\n count: 1\n capabilities: [gpu]"
else
    GPU_CONFIG=""
fi

# Download model with resume capability and progress display
whiptail --title "Downloading Model" --infobox "Downloading model... This may take a while. Download will resume if interrupted." 10 60
if ! curl -L -C - --progress-bar -o /opt/openwebui/models/model.gguf "$MODEL_URL" 2>&1 | \
    stdbuf -oL tr '\r' '\n' | grep -o '[0-9]*\.[0-9]' | tail -1; then
    echo "Error: Failed to download model"
    exit 1
fi

# Create docker-compose.yml
cat > /opt/openwebui/docker-compose.yml << EOF
version: '3.8'
services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui
    volumes:
      - /opt/openwebui/data:/app/backend/data
      - /opt/openwebui/models:/app/backend/models
    ports:
      - "${WEBUI_PORT}:8080"
    environment:
      - SECRET_KEY=${SECRET_KEY}
    restart: unless-stopped${GPU_CONFIG}
EOF

echo "Setup complete! Navigate to /opt/openwebui and run 'docker compose up -d' to start OpenWebUI."
