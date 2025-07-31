#!/bin/bash

# Update Script for Portainer and NPMplus
# Run this on your VPS (162.19.248.178)

set -e  # Exit on any error

echo "🚀 Starting service updates..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script with sudo"
    exit 1
fi

# Update system packages first
print_status "📦 Updating system packages..."
apt update && apt upgrade -y

# Function to update Docker image
update_docker_service() {
    local service_name=$1
    local image_name=$2
    local container_name=$3
    
    print_status "🔄 Updating $service_name..."
    
    # Check if container exists
    if docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        print_status "Found existing $service_name container"
        
        # Stop the container
        print_status "Stopping $service_name..."
        docker stop $container_name
        
        # Remove the container (keep volumes)
        print_status "Removing old $service_name container..."
        docker rm $container_name
        
        # Pull latest image
        print_status "Pulling latest $image_name image..."
        docker pull $image_name
        
        # Start new container with same configuration
        print_status "Starting new $service_name container..."
        
        if [ "$service_name" = "Portainer" ]; then
            # Portainer configuration
            docker run -d \
                --name $container_name \
                --restart=unless-stopped \
                -p 9000:9000 \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v portainer_data:/data \
                $image_name
        elif [ "$service_name" = "NPMplus" ]; then
            # NPMplus configuration
            docker run -d \
                --name $container_name \
                --restart=unless-stopped \
                -p 80:80 \
                -p 81:81 \
                -p 443:443 \
                -v npm_data:/data \
                -v npm_letsencrypt:/etc/letsencrypt \
                $image_name
        fi
        
        print_status "✅ $service_name updated successfully!"
    else
        print_warning "$service_name container not found. Skipping..."
    fi
}

# Update Portainer
update_docker_service "Portainer" "portainer/portainer-ce:latest" "portainer"

# Update NPMplus
update_docker_service "NPMplus" "zoeyvid/npmplus:latest" "npmplus"

# Wait for services to start
print_status "⏳ Waiting for services to start..."
sleep 10

# Check service status
print_status "📊 Checking service status..."

echo ""
echo "=== Portainer Status ==="
if docker ps | grep -q portainer; then
    print_status "✅ Portainer is running"
    echo "   Access: http://162.19.248.178:9000"
else
    print_error "❌ Portainer is not running"
fi

echo ""
echo "=== NPMplus Status ==="
if docker ps | grep -q npmplus; then
    print_status "✅ NPMplus is running"
    echo "   Access: http://162.19.248.178:81"
else
    print_error "❌ NPMplus is not running"
fi

# Check for any failed containers
echo ""
echo "=== Failed Containers ==="
failed_containers=$(docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}")
if [ -n "$failed_containers" ]; then
    print_warning "Found failed containers:"
    echo "$failed_containers"
else
    print_status "✅ No failed containers found"
fi

# Show all running containers
echo ""
echo "=== All Running Containers ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

print_status "🎉 Update completed!"
echo ""
echo "📋 Next steps:"
echo "1. Check Portainer: http://162.19.248.178:9000"
echo "2. Check NPMplus: http://162.19.248.178:81"
echo "3. Verify your calendar is still working: https://calendar.djmarkuss.de" 