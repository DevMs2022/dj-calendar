#!/bin/bash

# DJ Calendar HTTPS Deployment Script
echo "🔒 Deploying DJ Calendar with HTTPS..."

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

# Create necessary directories
mkdir -p logs ssl certbot/conf certbot/www

# Get domain name from user
echo "🌐 Enter your domain name (e.g., calendar.yourdomain.com):"
read DOMAIN_NAME

# Get email for Let's Encrypt
echo "📧 Enter your email address for SSL certificate:"
read EMAIL_ADDRESS

# Update docker-compose-https.yml with domain and email
sed -i "s/your-domain.com/$DOMAIN_NAME/g" docker-compose-https.yml
sed -i "s/your-email@example.com/$EMAIL_ADDRESS/g" docker-compose-https.yml

# Update nginx-https.conf with domain
sed -i "s/your-domain.com/$DOMAIN_NAME/g" nginx-https.conf

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose -f docker-compose-https.yml down

# Build and start the application
echo "🔨 Building and starting the application with HTTPS..."
docker-compose -f docker-compose-https.yml up --build -d

# Wait a moment for the container to start
sleep 10

# Check if the container is running
if docker-compose -f docker-compose-https.yml ps | grep -q "Up"; then
    echo "✅ Calendar deployed successfully with HTTPS!"
    echo "🔒 HTTPS URL: https://$DOMAIN_NAME"
    echo "📅 For Nicepage embed, use: https://$DOMAIN_NAME/calendar"
    echo ""
    echo "📋 Useful commands:"
    echo "  View logs: docker-compose -f docker-compose-https.yml logs -f"
    echo "  Stop: docker-compose -f docker-compose-https.yml down"
    echo "  Restart: docker-compose -f docker-compose-https.yml restart"
    echo "  Renew SSL: docker-compose -f docker-compose-https.yml run certbot renew"
else
    echo "❌ Deployment failed. Check logs with: docker-compose -f docker-compose-https.yml logs"
    exit 1
fi 