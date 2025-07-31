# DJ Calendar - Docker Deployment

A Docker-deployable DJ event calendar that fetches events from Google Calendar API.

## 🚀 Quick Start

### Local Development
```bash
# Clone the repository
git clone https://github.com/DevMs2022/dj-calendar.git
cd dj-calendar

# Run with Docker Compose
docker compose up -d --build

# Access the calendar
open http://localhost:3000
```

### VPS Deployment
```bash
# SSH to your VPS
ssh ubuntu@your-vps-ip

# Clone and deploy
git clone https://github.com/DevMs2022/dj-calendar.git /opt/dj-calendar
cd /opt/dj-calendar
docker compose up -d --build
```

## 📋 Requirements

- Docker & Docker Compose
- Python 3.11+
- Flask 3.0.0
- Google Calendar API access

## 🔧 Configuration

### Environment Variables
- `PORT`: Server port (default: 5000)
- `GOOGLE_CALENDAR_ID`: Your Google Calendar ID

### Port Mapping
- **Local:** `3000:5000` (host:container)
- **VPS:** `3000:5000` (host:container)

## 🌐 Access URLs

- **Local:** `http://localhost:3000`
- **VPS:** `http://your-vps-ip:3000`
- **Domain:** `https://calendar.djmarkuss.de`

## 📱 Embedding

### Full Width & Height Iframe
```html
<iframe 
    src="https://calendar.djmarkuss.de" 
    style="width: 100vw; height: 100vh; border: none; margin: 0; padding: 0; position: fixed; top: 0; left: 0; z-index: 1000;"
    frameborder="0"
    allowfullscreen>
</iframe>
```

### Responsive Iframe (Recommended)
```html
<iframe 
    src="https://calendar.djmarkuss.de" 
    style="width: 100%; height: 100vh; border: none; margin: 0; padding: 0;"
    frameborder="0"
    allowfullscreen>
</iframe>
```

### Standard Iframe
```html
<iframe 
    src="https://calendar.djmarkuss.de" 
    width="100%" 
    height="600px" 
    frameborder="0">
</iframe>
```

## 🔒 Security

- **X-Frame-Options:** `ALLOWALL` (allows iframe embedding)
- **Content-Security-Policy:** Configured for Google Calendar API
- **HTTPS:** Supported via NPMplus proxy

## 🛠️ Maintenance

### Update Calendar
```bash
# Pull latest changes
git pull origin master

# Rebuild and restart
docker compose down
docker compose up -d --build
```

### Check Status
```bash
# Container status
docker ps | grep dj-calendar

# Container logs
docker logs dj-calendar
```

## 📁 File Structure

```
dj-calendar/
├── event_calendar.html          # Original calendar file
├── event_calendar_minified.html # Minified version for deployment
├── server.py                    # Flask server
├── requirements.txt             # Python dependencies
├── Dockerfile                   # Docker image definition
├── docker-compose.yml          # Docker Compose configuration
├── nginx-npmplus.conf          # Nginx config for NPMplus
└── README.md                   # This file
```

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   # Check what's using the port
   sudo netstat -tlnp | grep :3000
   
   # Change port in docker-compose.yml
   ports:
     - "8080:5000"  # Use different host port
   ```

2. **Container won't start:**
   ```bash
   # Check logs
   docker logs dj-calendar
   
   # Rebuild from scratch
   docker compose down
   docker system prune -f
   docker compose up -d --build
   ```

3. **Calendar not loading:**
   - Check Google Calendar API credentials
   - Verify calendar ID is correct
   - Check browser console for errors

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review container logs
3. Verify network connectivity
4. Test with different browsers

---

**Last Updated:** July 31, 2025
**Version:** 1.0.0 