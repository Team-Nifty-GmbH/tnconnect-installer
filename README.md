# tnconnect-installer

## Prerequisites
Make sure the domain you are intstalling is pointing to the server you are installing on.
Also keep in mind that this install script will assume you are using a subdomain of your main domain 
prefixed with `connect.` eg. `connect.example.com`. when the domain is example.com.

## Installation
Copy this repo to your home directory and run the install script.

    $ git clone https://github.com/Team-Nifty-GmbH/tnconnect-installer.git

    $ cd tnconnect-installer

    $ sh ./install.sh

While the script is running you will be asked for the domain you want to use for your connect instance.
When running this script for the first time and you are cloning from a private repo you will see a public key.
You will need to add this key to your github repo as a deploy key. 
This will allow the script to pull the repo and install it.

## What does it do?

The install script will install the following software:
1. nginx
2. certbot
3. php with extensions
4. mariadb
5. [Docker](https://get.docker.com)
6. [Docker Compose](https://get.docker.com)
    1. [Meilisearch](https://hub.docker.com/r/getmeili/meilisearch)
    1. [Gotenberg](https://hub.docker.com/r/gotenberg/gotenberg)
7. supervisor
    1. [laravel queue worker](https://laravel.com/docs/master/queues)
    2. [laravel websockets](https://beyondco.de/docs/laravel-websockets/)
8. redis
9. [composer](https://getcomposer.org)

Additionaly the cronjob for the laravel scheduler will be installed.
