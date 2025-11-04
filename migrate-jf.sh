#!/bin/bash
set -e

# === CONFIG ===
JF_VERSION="10.10.7"
BACKUP_ZIP="/mnt/usb/bu.zip"
JF_USER="jellyfin"
JF_GROUP="jellyfin"
CONFIG_DIR="/etc/jellyfin"
DATA_DIR="/var/lib/jellyfin"
CACHE_DIR="/var/cache/jellyfin"

echo "🔧 Updating system and installing dependencies..."
apt update -y
apt install -y apt-transport-https gnupg unzip curl ffmpeg

echo "📦 Adding Jellyfin repository for Debian 12 (Bookworm)..."
wget -O- https://repo.jellyfin.org/debian/jellyfin_team.gpg.key | gpg --dearmor -o /usr/share/keyrings/jellyfin-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jellyfin-archive-keyring.gpg arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/debian bookworm main" \
  > /etc/apt/sources.list.d/jellyfin.list

echo "📥 Installing Jellyfin version $JF_VERSION..."
apt update -y
apt install -y jellyfin=${JF_VERSION}-*

echo "📦 Extracting backup from $BACKUP_ZIP..."
mkdir -p /tmp/jfbu
unzip -o "$BACKUP_ZIP" -d /tmp/jfbu

echo "🧹 Stopping Jellyfin service..."
systemctl stop jellyfin || true

echo "🧨 Wiping old config and data..."
rm -rf "$CONFIG_DIR" "$DATA_DIR" "$CACHE_DIR"
mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$CACHE_DIR"

echo "📂 Restoring from backup..."
if [ -d /tmp/jfbu/ProgramData/Jellyfin/Server ]; then
    cp -r /tmp/jfbu/ProgramData/Jellyfin/Server/* "$CONFIG_DIR"/
fi
if [ -d /tmp/jfbu/ProgramData/Jellyfin/data ]; then
    cp -r /tmp/jfbu/ProgramData/Jellyfin/data/* "$DATA_DIR"/
fi
if [ -d /tmp/jfbu/ProgramData/Jellyfin/cache ]; then
    cp -r /tmp/jfbu/ProgramData/Jellyfin/cache/* "$CACHE_DIR"/
fi

echo "🔑 Fixing permissions..."
chown -R $JF_USER:$JF_GROUP "$CONFIG_DIR" "$DATA_DIR" "$CACHE_DIR"

echo "🚀 Restarting Jellyfin..."
systemctl enable jellyfin
systemctl start jellyfin

sleep 5
systemctl status jellyfin --no-pager || true

echo "✅ Migration complete!"
IP=$(hostname -I | awk '{print $1}')
echo "🌐 Access Jellyfin at: http://$IP:8096"
