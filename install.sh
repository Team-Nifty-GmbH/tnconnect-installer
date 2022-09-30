#!/bin/bash
sudo NEEDRESTART_SUSPEND=1
sudo DEBIAN_FRONTEND=noninteractive apt update && sudo apt -y upgrade

if [ ! -f /usr/bin/dialog ]; then
  sudo apt install -y dialog
fi

if [ ! -f ~/.ssh/tnconnect.pub ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/tnconnect
fi

if [ -f ./tnconnect.domain ];
then
    hostname=$(cat ./tnconnect.domain)
else
    dialog --title "Enter domain without http(s)://" --inputbox "Enter domain without http(s)://" 8 60 2> ./tnconnect.domain
    hostname=$(cat ./tnconnect.domain)
fi

if [ -z "$hostname" ]
then
  echo "hostname is empty"
  exit 0
fi

# Install nginx
if service --status-all | grep -Fq 'nginx'; then
    echo "nginx is installed"
else
  sudo DEBIAN_FRONTEND=noninteractive apt install nginx -y
  sudo ufw allow 'Nginx Full'
  sudo mkdir -p /var/www/$hostname
  sudo chown -R www-data:wwww-data /var/www/$hostname
  sudo chmod -R 755 /var/www/$hostname
  sudo cp ./nginx /etc/nginx/sites-available/$hostname
  sudo unlink /etc/nginx/sites-enabled/default
  sudo sed -i "s/{\$hostname}/$hostname/g" /etc/nginx/sites-available/$hostname
  sudo ln -s /etc/nginx/sites-available/$hostname /etc/nginx/sites-enabled/
  sudo nginx -t
  sudo systemctl restart nginx
fi

# Install Certbot
if [ ! -f /usr/bin/certbot ]; then
  sudo DEBIAN_FRONTEND=noninteractive apt install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d admin.$hostname -d connect.$hostname
fi

# Install php
if [ ! -f /usr/bin/php ]
then
	sudo DEBIAN_FRONTEND=noninteractive apt install lsb-release ca-certificates apt-transport-https software-properties-common -y
	sudo apt-add-repository ppa:ondrej/php -y
  sudo DEBIAN_FRONTEND=noninteractive apt update
  sudo DEBIAN_FRONTEND=noninteractive apt -y install unzip
  sudo DEBIAN_FRONTEND=noninteractive apt -y install php8.1
  sudo DEBIAN_FRONTEND=noninteractive apt -y install php8.1-fpm php8.1-redis php8.1-bcmath php8.1-xml php8.1-fpm php8.1-mysql php8.1-zip php8.1-intl php8.1-ldap php8.1-gd php8.1-cli php8.1-bz2 php8.1-curl php8.1-mbstring
  sudo systemctl restart nginx
fi

# Install mariadb
if service --status-all | grep -Fq 'mariadb'; then
    echo "mariadb is installed"
else
sudo DEBIAN_FRONTEND=noninteractive apt install mariadb-server -y
sudo mysql_secure_installation
sudo mysql -u root -p << EOF
CREATE DATABASE tnconnect;
CREATE USER 'tnconnect'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON tnconnect.* TO 'tnconnect'@'localhost';
FLUSH PRIVILEGES;
exit
EOF
fi

# Install docker
if service --status-all | grep -Fq 'docker'; then
    echo "Docker is already installed"
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable docker
    sudo systemctl start docker
fi

if [ ! -f /opt/docker/docker-compose.yml ]
then
  cp -r ./docker /opt/
  meilisearchKey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  sed -i "s/MEILI_MASTER_KEY:.*/MEILI_MASTER_KEY: '$meilisearchKey'/" /opt/docker/docker-compose.yml
  docker compose -f /opt/docker/docker-compose.yml up -d
fi

# Install supervisor
if service --status-all | grep -Fq 'supervisor'; then
    echo "supervisor is installed"
else
    sudo DEBIAN_FRONTEND=noninteractive apt -y install supervisor
    cp ./laravel.conf /etc/supervisor/conf.d/
    sed -i "s/tnconnect/$hostname/" /etc/supervisor/conf.d/laravel.conf
fi

# Install Redis
if service --status-all | grep -Fq 'redis-server'; then
  echo "Redis is already installed"
else
  sudo DEBIAN_FRONTEND=noninteractive apt -y install redis-server
  sudo systemctl enable redis-server.service
  sudo systemctl start redis-server.service
  redispassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  sed -i "s/# requirepass foobared/requirepass $redispassword/" /etc/redis/redis.conf
  sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
  sudo systemctl restart redis.service
fi


# Install composer
if [ ! -f /usr/local/bin/composer ]
then
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
fi

# Install the app itself
if [ ! -f ~/.ssh/config ]
then
	cp ./config ~/.ssh/config
fi

if [ ! -d /var/www/$hostname/.git ]
then
	rm -rf /var/www/$hostname/*
	echo "-----------------------------------------------"
	cat ~/.ssh/tnconnect.pub
	echo "-----------------------------------------------"
	echo "Add the above key to the deploy keys account"
	echo "-----------------------------------------------"
	read -p -r "Type yes to confirm you added the key to the deploy keys (yes/no) " yn

  case $yn in
  	yes ) echo ok, we will proceed;;
  	* ) exit 0;;
  esac

  git clone git@tnconnect:Team-Nifty-GmbH/tnconnect-api.git /var/www/$hostname
fi

if [ ! -f /var/www/$hostname/.env ]
then
        sudo cp /var/www/$hostname/.env.example /var/www/$hostname/.env
        sed -i "s/APP_URL=.*/APP_URL=https:\/\/admin.$hostname/" /var/www/$hostname/.env
        sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" /var/www/$hostname/.env
        sed -i "s/APP_ENV=.*/APP_ENV=production/" /var/www/$hostname/.env
        sed -i "s/APP_LOCALE=.*/APP_LOCALE=de_DE/" /var/www/$hostname/.env
        sed -i "s/LOG_CHANNEL=.*/LOG_CHANNEL=database/" /var/www/$hostname/.env
        sed -i "s/PORTAL_DOMAIN=.*/PORTAL_DOMAIN=connect.$hostname/" /var/www/$hostname/.env
        sed -i "s/DB_HOST=.*/DB_HOST=localhost/" /var/www/$hostname/.env
        sed -i "s/DB_DATABASE=.*/DB_DATABASE=tnconnect/" /var/www/$hostname/.env
        sed -i "s/DB_USERNAME=.*/DB_USERNAME=tnconnect/" /var/www/$hostname/.env
        sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=password/" /var/www/$hostname/.env
        sed -i "s/REDIS_HOST=.*/REDIS_HOST=localhost/" /var/www/$hostname/.env
        sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$redispassword/" /var/www/$hostname/.env
        sed -i "s/MEILISEARCH_KEY=.*/MEILISEARCH_KEY=$meilisearchKey/" /var/www/$hostname/.env
        sed -i "s/MEILISEARCH_HOST=.*/MEILISEARCH_HOST=localhost:7700/" /var/www/$hostname/.env
        sed -i "s/GOTENBERG_HOST=.*/GOTENBERG_HOST=localhost/" /var/www/$hostname/.env
        sed -i "s/GOTENBERG_PORT=.*/GOTENBERG_HOST=3000/" /var/www/$hostname/.env
        sed -i "s/SCOUT_DRIVER=.*/SCOUT_DRIVER=meilisearch/" /var/www/$hostname/.env
        sed -i "s/SCOUT_QUEUE=.*/SCOUT_QUEUE=true/" /var/www/$hostname/.env
        sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=redis/" /var/www/$hostname/.env
        sed -i "s/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=redis/" /var/www/$hostname/.env
        sed -i "s/SESSION_DRIVER=.*/SESSION_DRIVER=redis/" /var/www/$hostname/.env
        sed -i "s/MEDIA_DISK=.*/MEDIA_DISK=media/" /var/www/$hostname/.env
        touch /var/www/$hostname/storage/logs/laravel.log

        chown -R www-data:www-data /var/www/$hostname
        sudo -u www-data composer i --working-dir=/var/www/$hostname --no-dev --no-interaction --no-ansi --no-plugins --no-progress --optimize-autoloader
        sudo -u www-data php /var/www/$hostname/artisan key:generate --no-interaction --no-ansi
        sudo echo "* * * * * www-data /usr/bin/php /var/www/$hostname/artisan schedule:run >> /dev/null 2>&1" >> /etc/crontab
        sudo -u www-data php /var/www/$hostname/artisan migrate --force --no-interaction --no-ansi
        sudo -u www-data php /var/www/$hostname/artisan db:init
        sudo -u www-data php /var/www/$hostname/artisan scout:import
fi

sudo supervisorctl reread
sudo supervisorctl update

git config --global --add safe.directory /var/www/$hostname
cd /var/www/$hostname/
git fetch
git pull origin dev

sudo -u www-data composer i  --working-dir=/var/www/$hostname --no-dev --no-interaction --no-ansi --no-plugins --no-progress --no-scripts --optimize-autoloader
sudo -u www-data php /var/www/$hostname/artisan migrate --force --no-interaction --no-ansi
sudo -u www-data php /var/www/$hostname/artisan storage:link
sudo -u www-data php /var/www/$hostname/artisan init:permissions
sudo -u www-data php /var/www/$hostname/artisan scout:sync
sudo -u www-data php /var/www/$hostname/artisan optimize
sudo -u www-data php /var/www/$hostname/artisan config:cache
sudo -u www-data php /var/www/$hostname/artisan view:cache
sudo -u www-data php /var/www/$hostname/artisan event:cache
sudo -u www-data php /var/www/$hostname/artisan queue:restart
sudo -u www-data php /var/www/$hostname/artisan scout:import
