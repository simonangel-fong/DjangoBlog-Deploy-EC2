#!/bin/bash
# Program Name: ec2-userdata.sh
# Author name: Wenhao Fang
# Date Created: Oct 21th 2023
# Date Modified: May 3rd 2024
# Current Repo: DjangoBlog-Deploy-EC2
# Project: DjangoBlog-Deploy-EC2
# Description of the script:
#   user data script to deploy the DjangoBlog project

REPO_NAME="DjangoBlog-Deploy-EC2"
PROJECT_NAME="DjangoBlog"
REPO_URL=https://github.com/simonangel-fong/$REPO_NAME.git

SECRET_KEY="django-insecure-0()30r0!^k(s*4jl01f6owz)6)gg8oqzd%j1cv4x&mm46l^ok6"
ALLOWED_HOSTS=127.0.0.1,localhost,$(curl -s https://api.ipify.org),blog.arguswatcher.net,www.blog.arguswatcher.net
DEBUG=TRUE

# Check if the log folder exists, and create it if not
if [ ! -d "/home/ubuntu/log" ]; then
    mkdir -p "/home/ubuntu/log"
fi

# Remove the old log file if it exists
if [ -f "/home/ubuntu/log/deploy.log" ]; then
    rm -f "/home/ubuntu/log/deploy.log"
fi

# Create a new log file
touch "/home/ubuntu/log/deploy.log"

# Start logging
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Deployment job starting..." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Update Linux
###########################################################
# update the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') OS - Update packages." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: OS - Update packages." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Upgrade Linux
###########################################################
# upgrade the package on Linux system.
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') OS - Upgrade packages." ">>/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: OS - Upgrade packages." ">>/home/ubuntu/log/deploy.log"

###########################################################
## Clear existing dir and files
###########################################################
# Check if the env folder exists
if [ -d "/home/ubuntu/env" ]; then
    # Remove the existing env folder and its contents
    rm -rf "/home/ubuntu/env" &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Remove existing env." >>"/home/ubuntu/log/deploy.log" ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Remove existing env." >>"/home/ubuntu/log/deploy.log"
else
    # Log a message if the env folder doesn't exist
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') No existing env to remove." >>"/home/ubuntu/log/deploy.log"
fi

# Check if the $REPO_NAME folder exists
if [ -d "/home/ubuntu/$REPO_NAME" ]; then
    # Remove the existing $REPO_NAME folder
    rm -rf "/home/ubuntu/$REPO_NAME" &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Remove existing repo." >>"/home/ubuntu/log/deploy.log" ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Remove existing repo." >>"/home/ubuntu/log/deploy.log"
else
    # Log a message if the $REPO_NAME folder doesn't exist
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') No existing repo to remove." >>"/home/ubuntu/log/deploy.log"
fi

###########################################################
## Clone github repo
###########################################################
# create dir for github repo
mkdir /home/ubuntu/$REPO_NAME/

# clone github repo
git clone $REPO_URL /home/ubuntu/$REPO_NAME &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Git - Clone github repo." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Git - Clone github repo." >>/home/ubuntu/log/deploy.log

###########################################################
## Creates virtual environment
###########################################################
## Install python3-venv package
sudo apt-get install -y python3-venv &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install python3-venv." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install python3-venv." >>"/home/ubuntu/log/deploy.log"

## Creates virtual environment
python3 -m venv /home/ubuntu/env &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: VENV - Create virtual environment." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Install gunicorn package within venv
###########################################################
source /home/ubuntu/env/bin/activate
pip install gunicorn &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Install gunicorn." >>/home/ubuntu/log/deploy.log
deactivate

###########################################################
## Update project dependencies
###########################################################
# Check if requirements.txt exists
if [ -f "/home/ubuntu/$REPO_NAME/$PROJECT_NAME/requirements.txt" ]; then
    source /home/ubuntu/env/bin/activate
    pip install -r /home/ubuntu/$REPO_NAME/$PROJECT_NAME/requirements.txt &&
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log ||
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Pip - Install project dependencies." >>/home/ubuntu/log/deploy.log
    deactivate
else
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Pip - No dependency to be installed." >>/home/ubuntu/log/deploy.log
fi

###########################################################
## Configuration gunicorn
###########################################################
sudo bash -c "sudo cat >/etc/systemd/system/gunicorn.socket <<SOCK 
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK" &&
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.socket." >>"/home/ubuntu/log/deploy.log" ||
    sudo echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.socket." >>"/home/ubuntu/log/deploy.log"

sudo bash -c "sudo cat >/etc/systemd/system/gunicorn.service <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/$REPO_NAME/$PROJECT_NAME
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    $PROJECT_NAME.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - Create gunicorn.service." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - Create gunicorn.service." >>"/home/ubuntu/log/deploy.log"

###########################################################
## Apply gunicorn configuration
###########################################################
sudo systemctl daemon-reload          # reload daemon
sudo systemctl start gunicorn.socket  # Start gunicorn
sudo systemctl enable gunicorn.socket # enable on boots
sudo systemctl restart gunicorn       # restart gunicorn

###########################################################
## Configuration nginx
###########################################################

# install nginx
sudo apt-get install -y nginx &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install nginx." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install nginx." >>"/home/ubuntu/log/deploy.log"

# overwrites user
sudo sed -i '1cuser root;' /etc/nginx/nginx.conf &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - overwrites user." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - overwrites user." >>/home/ubuntu/log/deploy.log

# create conf file
sudo bash -c "cat >/etc/nginx/sites-available/django.conf <<DJANGO_CONF
server {
listen 80;
server_name $(curl -s https://api.ipify.org) blog.arguswatcher.net www.blog.arguswatcher.net;
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/$REPO_NAME/$PROJECT_NAME;
}

location /media/ {
    root /home/ubuntu/$REPO_NAME/$PROJECT_NAME;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - create conf file." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - create conf file." >>/home/ubuntu/log/deploy.log

#  Creat link in sites-enabled directory
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - Creat link in sites-enabledr." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - Creat link in sites-enabledr." >>/home/ubuntu/log/deploy.log

# restart nginx
sudo nginx -t
sudo systemctl restart nginx
# sudo systemctl status nginx

###########################################################
## Configuration supervisor
###########################################################

# install supervisor
sudo apt-get install -y supervisor &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Package - Install supervisor." >>"/home/ubuntu/log/deploy.log" ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Package - Install supervisor." >>"/home/ubuntu/log/deploy.log"

# create directory for logging
sudo mkdir -p /var/log/gunicorn

# create configuration file
sudo bash -c "cat >/etc/supervisor/conf.d/gunicorn.conf  <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/$REPO_NAME/$PROJECT_NAME
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  $PROJECT_NAME.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Supervisor - create directory for logging." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Supervisor - create directory for logging." >>/home/ubuntu/log/deploy.log

sudo systemctl daemon-reload
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration
sudo supervisorctl reload # Restarted supervisord

###########################################################
## Create .env file to store secret
###########################################################
touch /home/ubuntu/$REPO_NAME/$PROJECT_NAME/$PROJECT_NAME/.env

sudo bash -c "cat >/home/ubuntu/$REPO_NAME/$PROJECT_NAME/$PROJECT_NAME/.env  <<ENV_FILE
SECRET_KEY=$SECRET_KEY
ALLOWED_HOSTS=$ALLOWED_HOSTS
DEBUG=$DEBUG
ENV_FILE" &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Create .env file." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Create .env file." >>/home/ubuntu/log/deploy.log

###########################################################
## Django Migrate
###########################################################
source /home/ubuntu/env/bin/activate
# django make migrations
python3 /home/ubuntu/$REPO_NAME/$PROJECT_NAME/manage.py makemigrations &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - make migrations." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - make migrations." >>/home/ubuntu/log/deploy.log

# django migrate
python3 /home/ubuntu/$REPO_NAME/$PROJECT_NAME/manage.py migrate &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - migrate." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - migrate." >>/home/ubuntu/log/deploy.log

# # django collect static files
# python3 /home/ubuntu/$REPO_NAME/$PROJECT_NAME/manage.py collectstatic &&
#     echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - collect static files." >>/home/ubuntu/log/deploy.log ||
#     echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - collect static files." >>/home/ubuntu/log/deploy.log
# deactivate

# # django test
# python3 /home/ubuntu/$REPO_NAME/$PROJECT_NAME/manage.py runserver 0.0.0.0:8000 &&
#     echo -e "$(date +'%Y-%m-%d %H:%M:%S') Django - Test." >>/home/ubuntu/log/deploy.log ||
#     echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Django - Test." >>/home/ubuntu/log/deploy.log
# deactivate

# restart gunicorn
sudo service gunicorn restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Gunicorn - restart service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Gunicorn - restart service." >>/home/ubuntu/log/deploy.log

# restart nginx
sudo service nginx restart &&
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Nginx - restart service." >>/home/ubuntu/log/deploy.log ||
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') Fail: Nginx - restart service." >>/home/ubuntu/log/deploy.log

# log finish deployment
echo -e "$(date +'%Y-%m-%d %H:%M:%S') Deployment completed." >>/home/ubuntu/log/deploy.log

# Troubleshooting
sudo nginx -t
sudo systemctl reload nginx
sudo service nginx restart
sudo supervisorctl reread
sudo supervisorctl reload
sudo service gunicorn restart
