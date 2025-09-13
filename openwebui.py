#!/bin/bash
# OpenWebUI One-Shot Setup for Debian 12 LXC

# Exit on errors
set -e

echo "[1/7] Updating system..."
apt update && apt upgrade -y

echo "[2/7] Installing dependencies..."
apt install -y git python3 python3-pip python3-venv build-essential curl

echo "[3/7] Cloning OpenWebUI..."
cd /root
if [ ! -d OpenWebUI ]; then
    git clone https://github.com/oobabooga/OpenWebUI.git
fi
cd OpenWebUI

echo "[4/7] Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "[5/7] Creating systemd service..."
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

echo "[6/7] Enabling and starting service..."
systemctl daemon-reload
systemctl enable openwebui
systemctl start openwebui

echo "[7/7] Setup complete!"
echo "OpenWebUI should now be running at: http://$(hostname -I | awk '{print $1}'):7860"
