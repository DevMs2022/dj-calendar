#!/bin/bash

# DJ Calendar Docker Deployment Script
echo "🚀 Deploying DJ Calendar with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and back in, then run this script again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create logs directory
mkdir -p logs

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Build and start the application
echo "🔨 Building and starting the application..."
docker-compose up --build -d

# Wait a moment for the container to start
sleep 5

# Check if the container is running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Calendar deployed successfully!"
    echo "🔒 Access your calendar at: https://$(curl -s ifconfig.me):8443"
    echo "📅 For Nicepage embed, use: https://$(curl -s ifconfig.me):8443/calendar"
    echo ""
    echo "📋 Useful commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Stop: docker-compose down"
    echo "  Restart: docker-compose restart"
    echo "  Update: docker-compose pull && docker-compose up -d"
else
    echo "❌ Deployment failed. Check logs with: docker-compose logs"
    exit 1
fi 