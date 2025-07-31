#!/bin/bash

# DJ Calendar Deployment Script
echo "Setting up DJ Calendar on VPS..."

# Update system
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up nginx
sudo cp nginx.conf /etc/nginx/sites-available/calendar
sudo ln -sf /etc/nginx/sites-available/calendar /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Set up systemd service
sudo cp calendar.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable calendar.service
sudo systemctl start calendar.service

echo "Calendar server deployed!"
echo "Access your calendar at: http://your-domain.com"
echo "For Nicepage embed, use: http://your-domain.com/calendar" 