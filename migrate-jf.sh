#!/bin/bash
set -e

echo "[1/6] Stopping any running Jellyfin service..."
systemctl stop jellyfin || true

echo "[2/6] Installing dependencies..."
apt update
apt install -y apt-transport-https gnupg lsb-release curl ffmpeg

echo "[3/6] Downloading Jellyfin 10.10.7 for Debian 12..."
mkdir -p /tmp/jf-install
cd /tmp/jf-install

# Jellyfin 10.10.7 packages (Debian 12-compatible)
wget https://repo.jellyfin.org/releases/server/debian/versions/10.10.7/jellyfin_10.10.7-1_amd64.deb
wget https://repo.jellyfin.org/releases/server/debian/versions/10.10.7/jellyfin-ffmpeg_7.0.2-7-debian_amd64.deb

echo "[4/6] Installing Jellyfin..."
dpkg -i jellyfin*.deb || apt -f install -y

echo "[5/6] Restoring Jellyfin config and data..."
if [ -f /mnt/usb/bu.zip ]; then
    echo "Found bu.zip — extracting to /var/lib/jellyfin..."
    apt install -y unzip
    systemctl stop jellyfin || true
    rm -rf /var/lib/jellyfin/*
    unzip -o /mnt/usb/bu.zip -d /var/lib/jellyfin/
else
    echo "⚠️ No backup zip found at /mnt/usb/bu.zip. Skipping restore."
fi

chown -R jellyfin:jellyfin /var/lib/jellyfin
chmod -R 755 /var/lib/jellyfin

echo "[6/6] Starting Jellyfin service..."
systemctl enable jellyfin
systemctl start jellyfin

echo "✅ Jellyfin 10.10.7 installed and configured successfully!"
