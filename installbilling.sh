#!/bin/bash
set -e

# Warna
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}[+] Mengunduh tema billing...${NC}"
wget -q -O /root/billing.zip https://github.com/RexxHayanasi/Theme-Autoinstaller/raw/main/billing.zip

if [ ! -f "/root/billing.zip" ]; then
  echo -e "${RED}[!] Gagal mengunduh theme.${NC}"
  exit 1
fi

echo -e "${YELLOW}[+] Mengekstrak theme...${NC}"
unzip -oq /root/billing.zip -d /root/pterodactyl
sudo cp -rfT /root/pterodactyl /var/www/pterodactyl

echo -e "${YELLOW}[+] Install Node.js 20 dan Yarn...${NC}"
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn

echo -e "${YELLOW}[+] Build tema billing...${NC}"
cd /var/www/pterodactyl || { echo -e "${RED}Direktori /var/www/pterodactyl tidak ditemukan!${NC}"; exit 1; }

yarn add react-feather
php artisan migrate --force
yarn build:production
php artisan view:clear

# Bersihkan file sementara
rm -f /root/billing.zip
rm -rf /root/pterodactyl

echo -e "${GREEN}[✓] Installasi theme billing dengan Node.js 20 berhasil!${NC}"
