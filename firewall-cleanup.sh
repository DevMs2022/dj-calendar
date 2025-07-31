#!/bin/bash

# Firewall Cleanup Script for VPS
# This script removes duplicate and potentially unused ports

echo "🧹 Starting firewall cleanup..."

# Essential ports to keep (based on your services)
ESSENTIAL_PORTS=(
    22      # SSH
    80      # HTTP
    443     # HTTPS
    81      # webconfig.djmarkuss.de
    88      # djmarkuss.de
    9000    # portainer.djmarkuss.de
    11000   # cloud.djmarkuss.de
    5000    # calendar.djmarkuss.de (your new service)
)

# Ports that might be unused (check before removing)
POTENTIALLY_UNUSED=(
    8088    8086    2022    5004    5005    8888    465     587
    8080    9981    9982    2432    10000   3306    8090    8444
    8600    8610
)

echo "📋 Current firewall status:"
sudo ufw status numbered

echo ""
echo "🔍 Essential ports to keep:"
for port in "${ESSENTIAL_PORTS[@]}"; do
    echo "  - Port $port"
done

echo ""
echo "⚠️  Potentially unused ports (check before removing):"
for port in "${POTENTIALLY_UNUSED[@]}"; do
    echo "  - Port $port"
done

echo ""
echo "🚨 WARNING: This will remove many ports!"
echo "Make sure you know which services are using which ports."
echo ""

read -p "Do you want to continue with cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled."
    exit 1
fi

echo ""
echo "🧹 Removing potentially unused ports..."

# Remove potentially unused ports (IPv4)
for port in "${POTENTIALLY_UNUSED[@]}"; do
    echo "Removing port $port..."
    sudo ufw delete allow $port 2>/dev/null || echo "  Port $port not found or already removed"
done

# Remove duplicate entries (IPv6 versions)
echo ""
echo "🧹 Removing duplicate IPv6 entries..."

# Remove duplicate IPv6 rules for potentially unused ports
for port in "${POTENTIALLY_UNUSED[@]}"; do
    echo "Removing IPv6 port $port..."
    sudo ufw delete allow $port/tcp 2>/dev/null || echo "  IPv6 port $port/tcp not found"
done

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "📋 New firewall status:"
sudo ufw status numbered

echo ""
echo "🎯 Essential services should still work:"
echo "  - SSH (port 22)"
echo "  - HTTP/HTTPS (ports 80, 443)"
echo "  - webconfig.djmarkuss.de (port 81)"
echo "  - djmarkuss.de (port 88)"
echo "  - portainer.djmarkuss.de (port 9000)"
echo "  - cloud.djmarkuss.de (port 11000)"
echo "  - calendar.djmarkuss.de (port 5000)"

echo ""
echo "⚠️  If any service stops working, add the port back with:"
echo "  sudo ufw allow <port>" 