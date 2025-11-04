#!/bin/bash
set -e

echo "📦 Jellyfin Migration Script Starting..."

ZIP_PATH="/mnt/usb/bu.zip"
TARGET_DIR="/var/lib/jellyfin"
SERVICE="jellyfin"

# Sanity checks
if [ ! -f "$ZIP_PATH" ]; then
    echo "❌ Backup zip not found at $ZIP_PATH"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory $TARGET_DIR not found — is Jellyfin installed?"
    exit 1
fi

echo "🛑 Stopping Jellyfin service..."
systemctl stop $SERVICE

echo "🧹 Clearing existing Jellyfin data directory..."
rm -rf "${TARGET_DIR:?}/"*

echo "📂 Extracting backup..."
unzip -q "$ZIP_PATH" -d "$TARGET_DIR"

echo "🔧 Fixing permissions..."
chown -R jellyfin:jellyfin "$TARGET_DIR"

echo "🚀 Starting Jellyfin service..."
systemctl start $SERVICE

sleep 5

echo "🩺 Checking Jellyfin status..."
if systemctl is-active --quiet $SERVICE; then
    echo "✅ Jellyfin service is running."
else
    echo "❌ Jellyfin service failed to start. Check logs with: journalctl -u jellyfin -n 50"
    exit 1
fi

echo "🌐 Trying to reach Jellyfin web UI (localhost:8096)..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8096 | grep -q 200; then
    echo "🎉 Jellyfin is online and responding!"
else
    echo "⚠️ Could not confirm web response — open http://<your-LXC-IP>:8096 manually to verify."
fi

echo "✅ Migration complete! Enjoy your fully restored Jellyfin setup."
