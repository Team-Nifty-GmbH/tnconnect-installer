#!/bin/bash

cd /var/www/html/
git fetch
git pull origin dev

chown -R www-data:www-data .
sudo -u www-data composer i --no-interaction --no-ansi --no-plugins --no-progress
sudo -u www-data php artisan migrate --force
sudo -u www-data php artisan optimize:clear
sudo -u www-data php artisan optimize
sudo -u www-data php artisan event:clear
sudo -u www-data php artisan event:cache

sudo -u www-data php artisan init
