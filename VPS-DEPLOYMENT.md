# VPS Deployment Guide

## 🚀 **Manual Deployment Steps for VPS (162.19.248.178)**

### **Step 1: Connect to Your VPS**
```bash
ssh your-username@162.19.248.178
```

### **Step 2: Create Deployment Directory**
```bash
sudo mkdir -p /opt/dj-calendar
sudo chown $USER:$USER /opt/dj-calendar
cd /opt/dj-calendar
```

### **Step 3: Upload Files**
You have several options:

#### **Option A: Using SCP (from your local machine)**
```bash
# From your local machine, run:
scp -r ./* your-username@162.19.248.178:/opt/dj-calendar/
```

#### **Option B: Using Git (if you have a repository)**
```bash
# On the VPS:
git clone https://github.com/yourusername/dj-calendar.git .
```

#### **Option C: Manual file transfer**
Upload these files to `/opt/dj-calendar/`:
- `docker-compose.yml`
- `Dockerfile`
- `server.py`
- `requirements.txt`
- `event_calendar_minified.html`

### **Step 4: Deploy with Docker**
```bash
cd /opt/dj-calendar

# Build and start the container
docker compose up -d --build

# Check if it's running
docker ps

# Check logs if needed
docker compose logs -f
```

### **Step 5: Test the Deployment**
```bash
# Test locally on the VPS
curl http://localhost:5000

# Test from external (should work)
curl http://162.19.248.178:5000
```

### **Step 6: Verify NPMplus Configuration**
Your NPMplus should be configured as:
- **Domain:** `calendar.djmarkuss.de`
- **Scheme:** `http`
- **IP/Domain:** `162.19.248.178`
- **Port:** `5000`

## 🔧 **Troubleshooting**

### **Port 5000 Already in Use**
```bash
# Check what's using port 5000
sudo netstat -tlnp | grep :5000

# Kill the process if needed
sudo kill -9 <PID>
```

### **Docker Not Installed**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in
```

### **Docker Compose Not Installed**
```bash
sudo apt install docker-compose-plugin -y
```

### **Container Won't Start**
```bash
# Check logs
docker compose logs

# Check if port is available
sudo lsof -i :5000
```

## 📋 **Useful Commands**

```bash
# View container logs
docker compose logs -f

# Restart container
docker compose restart

# Stop container
docker compose down

# Update and redeploy
git pull origin main
docker compose up -d --build
```

## ✅ **Success Indicators**

- Container shows as "running" in `docker ps`
- `curl http://localhost:5000` returns HTML
- NPMplus shows "Online" status
- `https://calendar.djmarkuss.de` loads the calendar 