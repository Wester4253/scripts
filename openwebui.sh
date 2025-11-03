#!/bin/bash
# OpenWebUI One-Shot Setup for Debian 12 LXC

# Exit on errors
set -e

echo "[1/6] Installing dependencies..."
apt update && apt install -y git python3 python3-pip python3-venv build-essential curl

echo "[2/6] Cloning OpenWebUI..."
cd /root
if [ ! -d OpenWebUI ]; then
    if ! git clone https://github.com/oobabooga/OpenWebUI.git; then
        echo "Error: Failed to clone OpenWebUI repository"
        exit 1
    fi
fi
cd OpenWebUI

echo "[3/6] Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
if ! pip install -r requirements.txt; then
    echo "Error: Failed to install Python requirements"
    exit 1
fi

echo "[4/6] Creating systemd service..."
cat <<EOF > /etc/systemd/system/openwebui.service
[Unit]
Description=OpenWebUI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/OpenWebUI
ExecStart=/root/OpenWebUI/venv/bin/python /root/OpenWebUI/server.py --listen --port 7860
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "[5/6] Enabling and starting service..."
systemctl daemon-reload
systemctl enable openwebui
systemctl start openwebui

echo "[6/6] Setup complete!"
echo "OpenWebUI should now be running at: http://$(hostname -I | awk '{print $1}'):7860"
