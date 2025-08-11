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
-d learnly.co.za -d www.learnly.co.za \
--agree-tos -m admin@learnly.co.za --no-eff-email

 docker-compose restart nginx

 [ec2-user@ip-10-0-7-76 projects]$ docker run --rm -v /home/ec2-user/projects/certbot/www:/var/www/certbot -v /home/ec2-user/projects/certbot/conf:/etc/letsencrypt certbot/certbot certonly --webroot -w /var/www/certbot -d learnly.co.za -d www.learnly.co.za --agree-tos -m admin@learnly.co.za --no-eff-email
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for learnly.co.za and www.learnly.co.za
An unexpected error occurred:
too many failed authorizations (5) for "www.learnly.co.za" in the last 1h0m0s, retry after 2025-08-09 12:48:50 UTC: see https://letsencrypt.org/docs/rate-limits/#authorization-failures-per-hostname-per-account
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
[ec2-user@ip-10-0-7-76 projects]$ 