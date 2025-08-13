#!/bin/bash

# Learnly Static Files Collection Script
# This script collects Django static files and ensures they are available to nginx

echo "Collecting Django static files..."

# Collect static files in the API container
docker-compose exec learnly-api python manage.py collectstatic --noinput

echo "Static files collected successfully!"
echo "The admin interface should now have proper styling at http://13.246.77.68/admin/"
