hostname=$(cat ./tnconnect.domain)
if [ -z "$hostname" ]
then
  echo "hostname is empty"
  exit 0
fi

# Uninstall nginx
# Keep the installation itself and just remove the config
if service --status-all | grep -Fq 'nginx'; then
    echo "nginx is installed"
    sudo unlink /etc/nginx/sites-enabled/$hostname
    sudo rm /etc/nginx/sites-available/$hostname
    sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
else
    echo "nginx is not installed"
fi

# Install apache2
if service --status-all | grep -Fq 'apache2'; then
    echo "apache2 is installed"
else
  sudo DEBIAN_FRONTEND=noninteractive apt install apache2 -y
  sudo ufw allow 'Apache Full'
  sudo mkdir -p /var/www/$hostname
  sudo chown -R www-data:www-data /var/www/$hostname
  sudo chmod -R 755 /var/www/$hostname
  sudo cp ./apache2 /etc/apache2/sites-available/$hostname.conf
  sudo sed -i "s/{\$hostname}/$hostname/g" /etc/apache2/sites-available/$hostname.conf
  sudo a2ensite $hostname.conf
  sudo a2dissite 000-default.conf
  sudo systemctl restart apache2
fi

# Uninstall Certbot
if [ ! -f /usr/bin/certbot ]; then
  sudo DEBIAN_FRONTEND=noninteractive apt remove certbot python3-certbot-nginx -y
  sudo apt autoremove -y
fi

# Uninstall php
if [ ! -f /usr/bin/php ]
then
  echo "php is not installed"
else
  sudo DEBIAN_FRONTEND=noninteractive apt remove php8.2 -y
  sudo DEBIAN_FRONTEND=noninteractive apt remove php8.2-fpm php8.2-redis php8.2-bcmath php8.2-xml php8.2-fpm php8.2-mysql php8.2-zip php8.2-intl php8.2-ldap php8.2-gd php8.2-cli php8.2-bz2 php8.2-curl php8.2-mbstring -y
  sudo systemctl restart nginx
fi

# Uninstall mariadb
if service --status-all | grep -Fq 'mariadb'; then
    echo "mariadb is installed"
    sudo DEBIAN_FRONTEND=noninteractive apt remove mariadb-server -y
else
    echo "mariadb is not installed"
fi

# Uninstall docker
if service --status-all | grep -Fq 'docker'; then
    echo "docker is installed"
    sudo apt remove docker docker-engine docker.io containerd runc -y
    sudo apt autoremove -y
    rm -rf /opt/docker
else
    echo "docker is not installed"
fi

# Uninstall supervisor
if service --status-all | grep -Fq 'supervisor'; then
    echo "supervisor is installed"
    rm -rf /opt/supervisor
    sudo apt remove supervisor -y
    sudo apt autoremove -y
    rm -rf /opt/supervisor
else
    echo "supervisor is not installed"
fi

# Uninstall redis
if service --status-all | grep -Fq 'redis'; then
    echo "redis is installed"
    sudo apt remove redis-server -y
    sudo apt autoremove -y
else
    echo "redis is not installed"
fi

# Uninstall meilisearch
if service --status-all | grep -Fq 'meilisearch'; then
    sudo service meilisearch stop
    sudo systemctl disable meilisearch
    sudo rm -rf /usr/local/bin/meilisearch
    sudo rm /etc/systemd/system/meilisearch.service
    sudo rm -rf /var/lib/meilisearch
    sudo rm /etc/meilisearch.toml
    sudo userdel -r meilisearch
else
    echo "meilisearch is not installed"
fi

# Uninstall composer
if [ ! -f /usr/bin/composer ]
then
  echo "composer is not installed"
else
  sudo rm -rf /usr/local/bin/composer
fi

# remove logrotate
sudo rm /etc/logrotate.d/$hostname

# Uninstall the app itself
sudo rm -rf /var/www/$hostname
