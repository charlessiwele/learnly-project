# Learnly Full Stack Deployment Guide

This guide explains how to deploy both the Learnly web application and API using Docker Compose.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx (80)    │    │  Learnly Web    │    │  Learnly API    │
│   Reverse Proxy │◄──►│   (Flask)       │◄──►│   (Django)      │
└─────────────────┘    │   Port: 5000    │    │   Port: 8000    │
                       └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │     Redis       │    │   PostgreSQL    │
                       │   (Sessions)    │    │   (Database)    │
                       │   Port: 6379    │    │   Port: 5432    │
                       └─────────────────┘    └─────────────────┘
```

## Prerequisites

- Docker and Docker Compose installed
- Git access to both learnly-api and learnly-web repositories
- At least 4GB RAM and 20GB disk space

## Quick Start

### 1. Clone Repositories

```bash
# Clone both repositories
git clone <learnly-api-repo-url> learnly-api
git clone <learnly-web-repo-url> learnly-web

# Navigate to project root
cd /path/to/learnly-project
```

### 2. Environment Setup

Create environment files for both services:

**learnly-api/.env:**
```bash
# Database Configuration
POSTGRES_DB=learnly_db
POSTGRES_USER=learnly_user
POSTGRES_PASSWORD=your_secure_password
DATABASE_URL=postgresql://learnly_user:your_secure_password@db:5432/learnly_db

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Django Configuration
DEBUG=False
DJANGO_SETTINGS_MODULE=learnly.settings.production
SECRET_KEY=your-django-secret-key

# AWS S3 Configuration (if using)
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_STORAGE_BUCKET_NAME=your_bucket_name
AWS_S3_REGION_NAME=af-south-1

# Email Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
ADMIN_EMAIL=admin@learnly.com

# Superuser Configuration
SUPERUSER_USERNAME=admin
SUPERUSER_EMAIL=admin@learnly.com
SUPERUSER_PASSWORD=admin123
SUPERUSER_FIRST_NAME=Admin
SUPERUSER_LAST_NAME=User
```

**learnly-web/.env:**
```bash
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-flask-secret-key
DEBUG=False

# API Configuration
API_BASE_URL=http://learnly-api:8000/api/v1

# Session Configuration
SESSION_TYPE=filesystem
SESSION_FILE_DIR=/app/flask_session
SESSION_FILE_THRESHOLD=500

# Redis Configuration (optional)
REDIS_URL=redis://redis:6379/0

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=/app/logs/learnly_web.log
```

### 3. Build and Deploy

```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Service Details

### Core Services

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| `nginx` | 80, 443 | Reverse proxy | N/A |
| `learnly-web` | 5000 | Flask web app | `/health` |
| `learnly-api` | 8000 | Django API | `/api/v1/health/` |
| `db` | 5432 | PostgreSQL | Database connectivity |
| `redis` | 6379 | Redis cache/sessions | Redis ping |

### Background Services

| Service | Description | Purpose |
|---------|-------------|---------|
| `learnly-api-celery` | Celery worker | Background task processing |
| `learnly-api-celery-beat` | Celery scheduler | Scheduled tasks |
| `learnly-api-flower` | Celery monitoring | Task monitoring (port 5555) |

## Access Points

Once deployed, you can access:

- **Web Application**: http://localhost/
- **API**: http://localhost/api/v1/
- **API Documentation**: http://localhost/api/docs/
- **Django Admin**: http://localhost/django-admin/
- **Celery Flower**: http://localhost:5555/
- **Health Checks**: 
  - Web: http://localhost/health
  - API: http://localhost/api/v1/health/

## Configuration Options

### 1. Development Mode

```bash
# Set environment variables for development
export DEBUG=True
export WEB_DEBUG=True
docker-compose up -d
```

### 2. Production Mode

```bash
# Set environment variables for production
export DEBUG=False
export WEB_DEBUG=False
docker-compose up -d
```

### 3. Scale Services

```bash
# Scale web application
docker-compose up --scale learnly-web=3 -d

# Scale API workers
docker-compose up --scale learnly-api-celery=2 -d
```

## Monitoring and Logs

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f learnly-web
docker-compose logs -f learnly-api

# Follow logs with timestamps
docker-compose logs -f --timestamps
```

### Health Monitoring

```bash
# Check service health
docker-compose ps

# Monitor resource usage
docker stats

# Check specific health endpoints
curl http://localhost/health
curl http://localhost/api/v1/health/
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check if ports are in use
   netstat -tulpn | grep -E ':(80|443|5000|8000|5432|6379)'
   ```

2. **Database Connection Issues**
   ```bash
   # Check database logs
   docker-compose logs db
   
   # Test database connection
   docker-compose exec db psql -U learnly_user -d learnly_db
   ```

3. **API Connection Issues**
   ```bash
   # Check API logs
   docker-compose logs learnly-api
   
   # Test API connectivity
   curl http://localhost/api/v1/health/
   ```

4. **Static Files Issues**
   ```bash
   # Collect static files
   docker-compose exec learnly-api python manage.py collectstatic --noinput
   
   # Check static files permissions
   docker-compose exec nginx ls -la /var/www/html/staticfiles/
   ```

### Debugging Commands

```bash
# Access container shells
docker-compose exec learnly-web bash
docker-compose exec learnly-api bash
docker-compose exec nginx sh

# Check network connectivity
docker-compose exec learnly-web ping learnly-api
docker-compose exec learnly-api ping learnly-web

# View container resources
docker-compose exec learnly-web top
docker-compose exec learnly-api top
```

## Backup and Recovery

### Database Backup

```bash
# Create database backup
docker-compose exec db pg_dump -U learnly_user learnly_db > backup.sql

# Restore database
docker-compose exec -T db psql -U learnly_user learnly_db < backup.sql
```

### Application Data Backup

```bash
# Backup static files
docker cp learnly-api:/app/staticfiles ./backup/staticfiles/

# Backup media files
docker cp learnly-api:/app/mediafiles ./backup/mediafiles/

# Backup web sessions
docker cp learnly-web:/app/flask_session ./backup/flask_session/
```

## Security Considerations

1. **Environment Variables**: Never commit `.env` files
2. **Secrets Management**: Use Docker secrets for production
3. **Network Security**: Restrict container communication
4. **Updates**: Regularly update base images and dependencies
5. **SSL/TLS**: Configure SSL certificates for production

## Performance Optimization

1. **Static Files**: Serve through Nginx with caching
2. **Database**: Optimize PostgreSQL configuration
3. **Redis**: Use for session storage and caching
4. **Load Balancing**: Scale horizontally with load balancer
5. **CDN**: Use CDN for static assets in production

## Maintenance

### Regular Tasks

1. **Update Dependencies**: Monthly
2. **Security Patches**: Weekly
3. **Log Rotation**: Daily
4. **Backup Verification**: Weekly
5. **Performance Monitoring**: Continuous

### Commands

```bash
# Update images
docker-compose pull

# Rebuild with new dependencies
docker-compose up --build -d

# Clean up unused resources
docker system prune -f

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Production Deployment

For production deployment, consider:

1. **SSL/TLS**: Configure SSL certificates
2. **Load Balancer**: Use external load balancer
3. **Monitoring**: Add monitoring and alerting
4. **Backup**: Configure automated backups
5. **Scaling**: Use container orchestration (Kubernetes)
6. **CI/CD**: Set up automated deployment pipeline 