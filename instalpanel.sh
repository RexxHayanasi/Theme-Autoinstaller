#!/bin/bash
# Auto Installer Pterodactyl Panel + Wings + Nginx + SSL + Admin User
# Tested on Ubuntu 20.04/22.04
# Run as root

DOMAIN="panel.rexxhayanasi.my.id"
EMAIL="admin@$DOMAIN"

echo "=== Update & install dependencies ==="
apt update -y && apt upgrade -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release unzip zip git

echo "=== Install MariaDB ==="
apt install -y mariadb-server mariadb-client
systemctl enable mariadb --now

echo "=== Secure MariaDB ==="
mysql_secure_installation <<EOF

y
y
y
y
EOF

echo "=== Install Redis & PHP ==="
apt install -y redis-server
apt install -y php8.1 php8.1-cli php8.1-gd php8.1-mysql \
php8.1-mbstring php8.1-bcmath php8.1-xml php8.1-curl \
php8.1-zip php8.1-common php8.1-fpm

systemctl enable --now redis-server
systemctl enable --now php8.1-fpm

echo "=== Install Composer ==="
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "=== Install Panel ==="
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache

cp .env.example .env
composer install --no-dev --optimize-autoloader

echo "=== Setup Database for Panel ==="
DB_PASS=$(openssl rand -base64 12)
mysql -u root -e "CREATE DATABASE panel;"
mysql -u root -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

sed -i "s|DB_HOST=127.0.0.1|DB_HOST=127.0.0.1|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=panel|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=ptero|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE=Asia/Tokyo|g" .env

php artisan key:generate --force
php artisan migrate --seed --force

echo "=== Buat Admin User ==="
php artisan p:user:make \
    --email="rexxhayanasi@dev.com" \
    --username="rexx" \
    --name-first="rexx" \
    --name-last="rexx" \
    --password="1" \
    --admin=1

chown -R www-data:www-data /var/www/pterodactyl/*

echo "=== Setup Nginx ==="
apt install -y nginx certbot python3-certbot-nginx
cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo "=== Install SSL Certbot ==="
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "=== Setup Queue Workers (Systemd) ==="
cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pteroq

echo "=== Install Wings (Daemon) ==="
mkdir -p /etc/pterodactyl
curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

echo "=== Install Docker for Wings ==="
apt install -y docker.io
systemctl enable --now docker
systemctl enable --now wings

echo "=== DONE ==="
echo "Panel installed at: https://${DOMAIN}"
echo "Admin login: rexxhayanasi@dev.com / 1"
echo "MySQL Panel DB User: ptero"
echo "MySQL Panel DB Pass: ${DB_PASS}"#!/bin/bash
# Auto Installer Pterodactyl Panel + Wings + Nginx + SSL + Admin User
# Tested on Ubuntu 20.04/22.04
# Run as root

DOMAIN="panel.rexxhayanasi.my.id"
EMAIL="admin@$DOMAIN"

echo "=== Update & install dependencies ==="
apt update -y && apt upgrade -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release unzip zip git

echo "=== Install MariaDB ==="
apt install -y mariadb-server mariadb-client
systemctl enable mariadb --now

echo "=== Secure MariaDB ==="
mysql_secure_installation <<EOF

y
y
y
y
EOF

echo "=== Install Redis & PHP ==="
apt install -y redis-server
apt install -y php8.1 php8.1-cli php8.1-gd php8.1-mysql \
php8.1-mbstring php8.1-bcmath php8.1-xml php8.1-curl \
php8.1-zip php8.1-common php8.1-fpm

systemctl enable --now redis-server
systemctl enable --now php8.1-fpm

echo "=== Install Composer ==="
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "=== Install Panel ==="
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache

cp .env.example .env
composer install --no-dev --optimize-autoloader

echo "=== Setup Database for Panel ==="
DB_PASS=$(openssl rand -base64 12)
mysql -u root -e "CREATE DATABASE panel;"
mysql -u root -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

sed -i "s|DB_HOST=127.0.0.1|DB_HOST=127.0.0.1|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=panel|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=ptero|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE=Asia/Tokyo|g" .env

php artisan key:generate --force
php artisan migrate --seed --force

echo "=== Buat Admin User ==="
php artisan p:user:make \
    --email="rexxhayanasi@dev.com" \
    --username="rexx" \
    --name-first="rexx" \
    --name-last="rexx" \
    --password="1" \
    --admin=1

chown -R www-data:www-data /var/www/pterodactyl/*

echo "=== Setup Nginx ==="
apt install -y nginx certbot python3-certbot-nginx
cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

echo "=== Install SSL Certbot ==="
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "=== Setup Queue Workers (Systemd) ==="
cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pteroq

echo "=== Install Wings (Daemon) ==="
mkdir -p /etc/pterodactyl
curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

echo "=== Install Docker for Wings ==="
apt install -y docker.io
systemctl enable --now docker
systemctl enable --now wings

echo "=== DONE ==="
echo "Panel installed at: https://${DOMAIN}"
echo "Admin login: rexxhayanasi@dev.com / 1"
echo "MySQL Panel DB User: ptero"
echo "MySQL Panel DB Pass: ${DB_PASS}"
