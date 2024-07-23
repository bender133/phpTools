docker-compose up -d --build

docker-compose exec app bash -c  "/var/www/php-tools/script.sh"
