# Learnly Project - SSL Setup and Management

## Overview
This project uses Let's Encrypt SSL certificates to secure the domains `learnly.co.za` and `bbrtc.learnly.co.za`. The SSL setup is managed through Certbot and integrated with Nginx for automatic HTTPS redirection.

## SSL Certificate Configuration

### Current Setup
- **Domains**: `learnly.co.za`, `www.learnly.co.za`, `bbrtc.learnly.co.za`, `www.bbrtc.learnly.co.za`
- **Certificate Provider**: Let's Encrypt
- **Certificate Management**: Certbot
- **Web Server**: Nginx (Docker container)
- **Certificate Path**: `/etc/letsencrypt/live/learnly.co.za/`

### Prerequisites
1. **DNS Configuration**: Ensure both domains point to your server's IP address
2. **Firewall**: Ports 80 and 443 must be open
3. **Docker**: Docker and Docker Compose must be installed
4. **Domain Ownership**: You must own the domains you're securing

## Initial SSL Certificate Setup

### Step 1: Prepare the Environment
```bash
cd /home/ec2-user/learnly-project/learnly-project

# Stop nginx service
docker-compose stop nginx
```

### Step 2: Create Temporary Nginx Configuration
Create `nginx_certbot.conf` for certificate generation:
```nginx
server {
    listen 80;
    server_name learnly.co.za www.learnly.co.za bbrtc.learnly.co.za www.bbrtc.learnly.co.za;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        default_type "text/plain";
        try_files $uri =404;
    }

    location / {
        return 200 "Certificate generation in progress";
        add_header Content-Type text/plain;
    }
}
```

### Step 3: Start Nginx with Temporary Config
```bash
# Temporarily modify docker-compose.yml to use nginx_certbot.conf
# Edit the nginx service volume mount line to:
# - ./nginx_certbot.conf:/etc/nginx/conf.d/default.conf

docker-compose up -d nginx
```

### Step 4: Generate SSL Certificates
```bash
docker run --rm -it \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/conf:/etc/letsencrypt \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/www:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d learnly.co.za \
  -d www.learnly.co.za \
  -d bbrtc.learnly.co.za \
  -d www.bbrtc.learnly.co.za
```

### Step 5: Verify Certificate Creation
```bash
ls -la /home/ec2-user/learnly-project/learnly-project/certbot/conf/live/
```

You should see a `learnly.co.za` directory containing:
- `fullchain.pem` (certificate chain)
- `privkey.pem` (private key)
- `cert.pem` (certificate)
- `chain.pem` (intermediate certificate)

### Step 6: Restore Production Configuration
```bash
# Stop nginx
docker-compose stop nginx

# Restore docker-compose.yml to use nginx_https.conf
# Edit the nginx service volume mount line back to:
# - ./nginx_https.conf:/etc/nginx/conf.d/default.conf

# Start nginx with SSL configuration
docker-compose up -d nginx
```

### Step 7: Test SSL Certificates
```bash
# Test main domain
curl -I https://learnly.co.za

# Test subdomain
curl -I https://bbrtc.learnly.co.za

# Test certificate validity
openssl s_client -connect learnly.co.za:443 -servername learnly.co.za < /dev/null
```

## SSL Certificate Renewal

### Automatic Renewal Setup

#### Step 1: Create Renewal Script
Create `renew_certs.sh`:
```bash
#!/bin/bash
cd /home/ec2-user/learnly-project/learnly-project

# Log renewal attempt
echo "$(date): Starting certificate renewal" >> /var/log/certbot-renew.log

# Stop nginx temporarily
docker-compose stop nginx

# Renew certificates
docker run --rm \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/conf:/etc/letsencrypt \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/www:/var/www/certbot \
  certbot/certbot renew --quiet

# Start nginx again
docker-compose up -d nginx

# Log completion
echo "$(date): Certificate renewal completed" >> /var/log/certbot-renew.log
```

#### Step 2: Make Script Executable
```bash
chmod +x renew_certs.sh
```

#### Step 3: Set Up Cron Job
```bash
# Edit crontab
crontab -e

# Add this line for daily renewal checks (runs at 2 AM)
0 2 * * * /home/ec2-user/learnly-project/learnly-project/renew_certs.sh >> /var/log/certbot-renew.log 2>&1
```

### Manual Renewal
```bash
cd /home/ec2-user/learnly-project/learnly-project

# Stop nginx
docker-compose stop nginx

# Renew certificates
docker run --rm \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/conf:/etc/letsencrypt \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/www:/var/www/certbot \
  certbot/certbot renew

# Start nginx
docker-compose up -d nginx
```

## SSL Configuration Files

### Nginx HTTPS Configuration (`nginx_https.conf`)
The main SSL configuration includes:
- SSL certificate and key paths
- Security headers (HSTS, CSP, etc.)
- Gzip compression
- Proxy settings for web and API services
- Static file serving

### Certificate Locations
- **Certificates**: `/home/ec2-user/learnly-project/learnly-project/certbot/conf/live/learnly.co.za/`
- **Webroot**: `/home/ec2-user/learnly-project/learnly-project/certbot/www/`
- **Nginx Mount**: `/etc/letsencrypt` (inside container)

## Troubleshooting SSL Issues

### Common Issues and Solutions

#### 1. Certificate Not Found
```bash
# Check if certificates exist
ls -la /home/ec2-user/learnly-project/learnly-project/certbot/conf/live/

# Check nginx configuration
docker-compose exec nginx nginx -t
```

#### 2. Certificate Expired
```bash
# Check certificate expiration
openssl x509 -in /home/ec2-user/learnly-project/learnly-project/certbot/conf/live/learnly.co.za/cert.pem -text -noout | grep "Not After"

# Force renewal
docker run --rm \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/conf:/etc/letsencrypt \
  -v /home/ec2-user/learnly-project/learnly-project/certbot/www:/var/www/certbot \
  certbot/certbot renew --force-renewal
```

#### 3. Rate Limiting (Too Many Failed Attempts)
If you hit Let's Encrypt rate limits:
- Wait for the specified time period
- Check DNS configuration
- Ensure ports 80 and 443 are accessible
- Verify domain ownership

#### 4. Nginx SSL Errors
```bash
# Check nginx error logs
docker-compose logs nginx

# Test nginx configuration
docker-compose exec nginx nginx -t

# Restart nginx
docker-compose restart nginx
```

### SSL Certificate Validation
```bash
# Test certificate chain
openssl verify -CAfile /home/ec2-user/learnly-project/learnly-project/certbot/conf/live/learnly.co.za/chain.pem /home/ec2-user/learnly-project/learnly-project/certbot/conf/live/learnly.co.za/cert.pem

# Test SSL handshake
openssl s_client -connect learnly.co.za:443 -servername learnly.co.za -showcerts
```

## Security Best Practices

1. **Automatic Renewal**: Always set up automatic renewal via cron
2. **Backup Certificates**: Regularly backup the certbot directory
3. **Monitor Expiration**: Set up monitoring for certificate expiration
4. **Security Headers**: Ensure proper security headers are configured
5. **Regular Updates**: Keep certbot and nginx updated

## Backup and Recovery

### Backup Certificates
```bash
# Create backup
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz /home/ec2-user/learnly-project/learnly-project/certbot/

# Store backup securely
# Consider encrypting the backup file
```

### Restore Certificates
```bash
# Stop services
docker-compose down

# Restore from backup
tar -xzf ssl-backup-YYYYMMDD.tar.gz -C /

# Start services
docker-compose up -d
```

---

# Check container health
docker-compose ps --format "table {{.Name}}\t{{.Service}}\t{{.Status}}\t{{.Ports}}\t{{.Health}}"


# Check manage nginx
sudo systemctl stop nginx

# Check specific service logs
docker-compose logs learnly-web
docker-compose logs learnly-api
docker-compose logs nginx
docker-compose logs learnly-api-celery
docker-compose logs api-celery-beat
docker-compose logs learnly-api-flower

To stream logs from all services in a Docker Compose setup, use the following terminal command:
docker-compose logs -f
Explanation:
logs: Fetches logs from services defined in your docker-compose.yml.
-f or --follow: Streams the logs in real-time (like tail -f).

Optional: Filter by service name
To stream logs from a specific service (e.g., web), run:

docker-compose logs -f learnly-web
docker-compose logs -f learnly-api
docker-compose logs -f nginx
docker-compose logs -f learnly-api-celery
docker-compose logs -f api-celery-beat
docker-compose logs -f learnly-api-flower

docker logs projects-learnly-web-1 --tail 20


docker-compose up -d --build
docker-compose restart
docker-compose restart nginx
docker-compose restart learnly-api
docker-compose restart learnly-web
docker-compose down learnly-web

# Test web access directly
curl -f http://34.252.123.188/health

# Test web container directly
curl -f http://localhost:5000/health

# Test API container directly  
curl -f http://localhost:8000/api/v1/health/

# Test if web container can reach API (use container name)
docker-compose exec learnly-web curl -f http://learnly-api:8000/api/v1/health/

# Test if API container can reach web (use container name)
docker-compose exec learnly-api curl -f http://learnly-web:5000/health

# Test if Nginx can reach web container
docker-compose exec nginx curl -f http://learnly-web:5000/health

# Test if Nginx can reach API container
docker-compose exec nginx curl -f http://learnly-api:8000/api/v1/health/

# Test with verbose output to see the full response
docker-compose exec nginx curl -v http://learnly-api:8000/api/v1/health/

# Test with localhost Host header
docker-compose exec nginx curl -H "Host: localhost" -f http://learnly-api:8000/api/v1/health/

# Test with explicit Host header
docker-compose exec nginx curl -H "Host: learnly-api" -f http://learnly-api:8000/api/v1/health/

# docker run -d --name web -p 80:80 -p 443:443 nginx:alpine

docker-compose logs -f learnly-web

docker run --rm \
-v /home/ec2-user/projects/certbot/www:/var/www/certbot \
-v /home/ec2-user/projects/certbot/conf:/etc/letsencrypt \
certbot/certbot certonly --webroot -w /var/www/certbot \
-d bbrtc.learnly.co.za -d www.bbrtc.learnly.co.za \
--agree-tos -m admin@learnly.co.za --no-eff-email

 docker-compose restart nginx

Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for learnly.co.za and www.learnly.co.za
An unexpected error occurred:
too many failed authorizations (5) for "www.learnly.co.za" in the last 1h0m0s, retry after 2025-08-09 12:48:50 UTC: see https://letsencrypt.org/docs/rate-limits/#authorization-failures-per-hostname-per-account
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
[ec2-user@ip-10-0-7-76 projects]$ 