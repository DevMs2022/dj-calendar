# DJ Event Calendar - Docker Deployment

This setup allows you to host your DJ Event Calendar on a VPS using Docker and embed it in Nicepage using a URL.

## 🐳 Quick Docker Setup

1. **Upload files to your VPS:**
   ```bash
   scp -r . user@your-vps-ip:/path/to/calendar/
   ```

2. **SSH into your VPS and run:**
   ```bash
   cd /path/to/calendar/
   ./docker-deploy.sh
   ```

3. **That's it!** The script will:
   - Install Docker if needed
   - Build and start the container
   - Show you the access URLs

## 🚀 Manual Docker Setup

### 1. Install Docker (if not already installed)
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in
```

### 2. Build and Run
```bash
# Build the image
docker build -t dj-calendar .

# Run the container
docker run -d -p 80:80 --name dj-calendar dj-calendar
```

### 3. Using Docker Compose (Recommended)
```bash
# Start the application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the application
docker-compose down
```

## Manual Setup (Alternative)

### 1. Install Dependencies
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx
```

### 2. Set Up Python Environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Test the Server
```bash
python server.py
```
Visit: `http://your-vps-ip:5000`

### 4. Set Up as Service
```bash
sudo cp calendar.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable calendar.service
sudo systemctl start calendar.service
```

### 5. Configure Nginx (Optional)
```bash
sudo cp nginx.conf /etc/nginx/sites-available/calendar
sudo ln -sf /etc/nginx/sites-available/calendar /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 🌐 Nicepage Embed

Once deployed with Docker, you can embed the calendar in Nicepage using:

**Option 1: Direct URL**
```
http://your-vps-ip:8080/calendar
```

**Option 2: Iframe Embed**
```html
<iframe src="http://your-vps-ip:8080/calendar" width="100%" height="600px" frameborder="0"></iframe>
```

**Option 3: With Domain (if you have one)**
```
http://your-domain.com:8080/calendar
```

## 📁 Files Created

### Docker Files
- `Dockerfile` - Docker image configuration
- `docker-compose.yml` - Docker Compose configuration
- `.dockerignore` - Files to exclude from Docker build
- `docker-deploy.sh` - Automated Docker deployment script

### Application Files
- `server.py` - Flask web server
- `requirements.txt` - Python dependencies
- `nginx.conf` - Nginx configuration (optimized for Docker)
- `event_calendar_minified.html` - Minified calendar file

## Security Notes

- Update the nginx configuration with your actual domain
- Consider adding SSL/HTTPS with Let's Encrypt
- Set up firewall rules to only allow necessary ports
- Use a non-root user for the service

## 🔧 Troubleshooting

### Docker Commands
- Check container status: `docker-compose ps`
- View logs: `docker-compose logs -f`
- Restart container: `docker-compose restart`
- Stop and remove: `docker-compose down`

### Manual Docker Commands
- Check running containers: `docker ps`
- View container logs: `docker logs dj-calendar`
- Access container shell: `docker exec -it dj-calendar bash`
- Check container resources: `docker stats dj-calendar`

### Network Issues
- Check if port 80 is open: `sudo netstat -tlnp | grep :80`
- Test nginx inside container: `docker exec dj-calendar nginx -t`
- Check firewall: `sudo ufw status` 