#!/bin/bash
set -e

# === CONFIG ===
BACKUP_ZIP="/mnt/usb/bu.zip"
JELLYFIN_DIR="/var/lib/jellyfin"
TMP_DIR="/tmp/jf-migrate"

echo "🧩 Jellyfin migration starting..."
echo "Backup file: $BACKUP_ZIP"
echo "Destination: $JELLYFIN_DIR"

# Stop Jellyfin service
echo "⏹️ Stopping Jellyfin..."
sudo systemctl stop jellyfin

# Create temp directory
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Unzip backup
echo "📦 Extracting backup..."
sudo unzip -o "$BACKUP_ZIP" -d "$TMP_DIR"

# Move extracted config (ProgramData equivalent)
echo "🗂️ Replacing Jellyfin configuration..."
sudo rsync -avh --delete "$TMP_DIR/" "$JELLYFIN_DIR/"

# Fix permissions (important!)
echo "🔧 Fixing permissions..."
sudo chown -R jellyfin:jellyfin "$JELLYFIN_DIR"

# Cleanup
rm -rf "$TMP_DIR"

# Restart Jellyfin
echo "🚀 Restarting Jellyfin..."
sudo systemctl start jellyfin

echo "✅ Migration complete!"
echo "Try accessing Jellyfin at http://<your-lxc-ip>:8096"
