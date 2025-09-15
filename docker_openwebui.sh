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
apt-get install -y curl whiptail docker.io docker-compose-v2

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
    GPU_CONFIG="    deploy:\n      resources:\n        reservations:\n          devices:\n            - driver: nvidia\n              count: 1\n              capabilities: [gpu]"
else
    GPU_CONFIG=""
fi

# Download model
whiptail --title "Downloading Model" --infobox "Downloading model... This may take a while." 10 60
curl -L -o /opt/openwebui/models/model.gguf "$MODEL_URL"

# Create docker-compose.yml
cat > /opt/openwebui/docker-compose.yml <<EOF
version: '3.8'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    privileged: true
    environment:
      - OLLAMA_BASE_URL=http://llama-cpp:8000
      - WEBUI_SECRET_KEY=$SECRET_KEY
    volumes:
      - ./data:/app/backend/data
    ports:
      - "$WEBUI_PORT:8080"
    depends_on:
      - llama-cpp
    networks:
      - app-network

  llama-cpp:
    image: ghcr.io/ggerganov/llama.cpp:server
    container_name: llama-cpp
    restart: unless-stopped
    privileged: true
    environment:
      - LLAMA_CPP_SERVER_PORT=8000
      - MODEL_PATH=/models/model.gguf
    volumes:
      - ./models:/models
    devices:
      - /dev/kvm:/dev/kvm
    cap_add:
      - ALL
    security_opt:
      - apparmor:unconfined
      - seccomp:unconfined
    networks:
      - app-network
$GPU_CONFIG

networks:
  app-network:
    driver: bridge
EOF

# Start containers
cd /opt/openwebui
docker compose up -d

# Show completion message
whiptail --title "Setup Complete!" --msgbox "OpenWebUI is now running at:\nhttp://$(hostname -I | awk '{print $1}'):$WEBUI_PORT\n\nSecret key: $SECRET_KEY\n\nData stored in: /opt/openwebui" 15 60
