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

# Uninstall php
if [ ! -f /usr/bin/php ]
then
  echo "php is not installed"
else
  sudo DEBIAN_FRONTEND=noninteractive apt remove php8.1 -y
  sudo DEBIAN_FRONTEND=noninteractive apt remove php8.1-fpm php8.1-redis php8.1-bcmath php8.1-xml php8.1-fpm php8.1-mysql php8.1-zip php8.1-intl php8.1-ldap php8.1-gd php8.1-cli php8.1-bz2 php8.1-curl php8.1-mbstring -y
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

# Uninstall composer
if [ ! -f /usr/bin/composer ]
then
  echo "composer is not installed"
else
  sudo rm -rf /usr/local/bin/composer
fi

# Uninstall the app itself
sudo rm -rf /var/www/$hostname
