#!/bin/bash

# SSL Certificate Renewal Script for Learnly Project
# This script automatically renews Let's Encrypt SSL certificates

set -e  # Exit on any error

# Configuration
PROJECT_DIR="/home/ec2-user/learnly-project/learnly-project"
LOG_FILE="/var/log/certbot-renew.log"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Change to project directory
cd "$PROJECT_DIR" || {
    log "ERROR: Could not change to project directory $PROJECT_DIR"
    exit 1
}

log "Starting SSL certificate renewal process"

# Check if certificates need renewal
log "Checking certificate expiration dates"
docker run --rm \
  -v "$PROJECT_DIR/certbot/conf:/etc/letsencrypt" \
  -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
  certbot/certbot certificates

# Stop nginx temporarily to free up port 80
log "Stopping nginx service"
docker-compose stop nginx

# Wait a moment for nginx to fully stop
sleep 5

# Renew certificates
log "Renewing certificates"
docker run --rm \
  -v "$PROJECT_DIR/certbot/conf:/etc/letsencrypt" \
  -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
  certbot/certbot renew --quiet --non-interactive

# Check if renewal was successful
if [ $? -eq 0 ]; then
    log "Certificate renewal completed successfully"
else
    log "ERROR: Certificate renewal failed"
    # Start nginx anyway to maintain service
    docker-compose up -d nginx
    exit 1
fi

# Start nginx again
log "Starting nginx service"
docker-compose up -d nginx

# Wait for nginx to start
sleep 10

# Test if nginx is running properly
if docker-compose ps nginx | grep -q "Up"; then
    log "Nginx started successfully"
else
    log "ERROR: Nginx failed to start properly"
    exit 1
fi

# Test SSL certificates
log "Testing SSL certificates"
if curl -s -I https://learnly.co.za > /dev/null 2>&1; then
    log "SSL certificate for learnly.co.za is working"
else
    log "WARNING: SSL certificate test for learnly.co.za failed"
fi

if curl -s -I https://bbrtc.learnly.co.za > /dev/null 2>&1; then
    log "SSL certificate for bbrtc.learnly.co.za is working"
else
    log "WARNING: SSL certificate test for bbrtc.learnly.co.za failed"
fi

log "SSL certificate renewal process completed"

# Optional: Send notification (uncomment and configure if needed)
# if command -v mail > /dev/null 2>&1; then
#     echo "SSL certificates renewed successfully on $(date)" | mail -s "SSL Renewal Success" your-email@example.com
# fi
