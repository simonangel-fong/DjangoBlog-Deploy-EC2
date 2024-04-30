# Document01 - Manual AWS EC2 Deployment

[Back](../README.md)

---

## Create EC2 Instance

- Using template to create EC2 instance
- define user data

```sh
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
```

- Install python3-venv package

```sh
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3-venv
```

- Establish virtual environment

```sh
# remove existing env
sudo rm -rf /home/ubuntu/env
python3 -m venv /home/ubuntu/env
```

- Download codes from github

```sh
# remove existing project directory
sudo rm -rf /home/ubuntu/DjangoBlog-Deploy-EC2
git clone https://github.com/simonangel-fong/DjangoBlog-Deploy-EC2.git /home/ubuntu/DjangoBlog-Deploy-EC2
```

- Install app dependencies

```sh
source /home/ubuntu/env/bin/activate
pip install -r /home/ubuntu/DjangoBlog-Deploy-EC2/requirements.txt
pip list
```

- Migrate App

```sh
python3 /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog/manage.py makemigrations
python3 /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog/manage.py migrate
```

- Test on EC2 with port 8000

```sh
python3 /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog/manage.py runserver 0.0.0.0:8000
```

- Update allow host

---

## Install and configure gunicorn

- Install gunicorn in venv

```sh
# require venv
pip install gunicorn
deactivate
```

- Configuration gunicorn.socket

```sh
socket_conf=/etc/systemd/system/gunicorn.socket

sudo bash -c "sudo cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK"
```

---

- Configuration gunicorn.service

```sh
service_conf=/etc/systemd/system/gunicorn.service

sudo bash -c "sudo cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    DjangoBlog.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE"
```

---

- Apply gunicorn configuration

```sh
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket
sudo systemctl status gunicorn
```

---

- Visit port 8000 to test

```sh
source /home/ubuntu/env/bin/activate
cd /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog
gunicorn --bind 0.0.0.0:8000 DjangoBlog.wsgi:application
cd ~
deactivate
```

---

## Install and configure nginx

- Install nginx

```sh
sudo apt-get install -y nginx
```

---

- modify nginx conf

```sh
nginx_conf=/etc/nginx/nginx.conf
sudo sed -i '1cuser root;' $nginx_conf
```

- create django.conf file

```sh
django_conf=/etc/nginx/sites-available/django.conf
sudo bash -c "cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name $(dig +short myip.opendns.com @resolver1.opendns.com);
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog;
}

location /media/ {
    root /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog;
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF"

```

- Creat link in sites-enabled directory

```sh
sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled
```

- Test and restart nginx

```sh
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
```

---

## Install and configure supervisor

- Install supervisor

```sh
sudo apt-get install -y supervisor
```

- Configuration supervisor

```sh
sudo mkdir -p /var/log/gunicorn # create directory for logging

supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
sudo bash -c "cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  DjangoBlog.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN"

```

---

- update supervisor

```sh
sudo supervisorctl reread # tell supervisor read configuration file
sudo supervisorctl update # update supervisor configuration

```

---

## Visit public IP

- Visit App with public IP

---

## Collect Static

```sh
python3 /home/ubuntu/DjangoBlog-Deploy-EC2/DjangoBlog/manage.py collectstatic
```

---

[TOP](#manual-aws-ec2-deployment)
