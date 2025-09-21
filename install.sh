#!/bin/bash

# Color
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Display welcome message
display_welcome() {
  clear
  echo -e "${BLUE}[+] AUTO INSTALLER THEMA by REXXHAYANASI [+]${NC}"
  echo
  sleep 2
  clear
}

# Update and install jq
install_jq() {
  echo -e "${BLUE}[+] UPDATE & INSTALL JQ [+]${NC}"
  sudo apt update && sudo apt install -y jq
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] INSTALL JQ BERHASIL [+]${NC}"
  else
    echo -e "${RED}[+] INSTALL JQ GAGAL [+]${NC}"
    exit 1
  fi
  sleep 1
  clear
}

# Check user token (bersih & aman)
check_token() {
  echo -e "${BLUE}[+] LICENSY BY RexxHayanasi [+]${NC}"
  echo -ne "${YELLOW}MASUKAN AKSES TOKEN : ${NC}"
  read -r USER_TOKEN

  if [ "$USER_TOKEN" = "RexxHayanasi" ]; then
    echo -e "${GREEN}AKSES BERHASIL${NC}"
    return 0
  else
    echo -e "${RED}Token Salah!${NC}"
    echo -e "${YELLOW}© RexxHayanasi${NC}"
    return 1
  fi
}

# Install theme (meminta token sebelum menjalankan)
install_theme() {
  # Minta token sebelum install (opsional)
  if ! check_token; then
    echo -e "${RED}Akses ditolak. Kembali ke menu.${NC}"
    sleep 1
    return
  fi

  clear
  echo -e "${BLUE}[+] INSTALL PTERODACTYL THEME [+]${NC}"
  echo ""
  echo -e "${YELLOW}PILIH THEME YANG INGIN DIINSTALL:${NC}"
  echo "1. Stellar"
  echo "2. Billing"
  echo "3. Enigma"
  echo "x. Kembali"
  echo -ne "${GREEN}Masukkan pilihan (1/2/3/x): ${NC}"
  read -r SELECT_THEME

  case "$SELECT_THEME" in
    1) THEME_NAME="stellar" ;;
    2) THEME_NAME="billing" ;;
    3) THEME_NAME="enigma" ;;
    x) return ;;
    *) echo -e "${RED}Pilihan tidak valid.${NC}"; sleep 1; install_theme; return ;;
  esac

  THEME_URL="https://github.com/RexxHayanasi/Theme-Autoinstaller/raw/main/${THEME_NAME}.zip"

  echo -e "${YELLOW}Mengunduh theme $THEME_NAME...${NC}"
  wget -q -O "/root/${THEME_NAME}.zip" "$THEME_URL"
  if [ ! -f "/root/${THEME_NAME}.zip" ]; then
    echo -e "${RED}Gagal mengunduh theme.${NC}"
    return
  fi

  unzip -oq "/root/${THEME_NAME}.zip" -d /root/pterodactyl

  if [ "$THEME_NAME" = "enigma" ]; then
    echo -ne "${YELLOW}Masukkan link WhatsApp (https://wa.me/...): ${NC}"; read -r LINK_WA
    echo -ne "${YELLOW}Masukkan link group: ${NC}"; read -r LINK_GROUP
    echo -ne "${YELLOW}Masukkan link channel: ${NC}"; read -r LINK_CHNL

    sed -i "s|LINK_WA|$LINK_WA|g" /root/pterodactyl/resources/scripts/components/dashboard/DashboardContainer.tsx
    sed -i "s|LINK_GROUP|$LINK_GROUP|g" /root/pterodactyl/resources/scripts/components/dashboard/DashboardContainer.tsx
    sed -i "s|LINK_CHNL|$LINK_CHNL|g" /root/pterodactyl/resources/scripts/components/dashboard/DashboardContainer.tsx
  fi

  echo -e "${YELLOW}Menginstall dependensi dan apply theme...${NC}"
  sudo cp -rfT /root/pterodactyl /var/www/pterodactyl

  curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  sudo npm install -g yarn

  cd /var/www/pterodactyl || { echo -e "${RED}Direktori tidak ditemukan!${NC}"; return; }

  yarn add react-feather
  php artisan migrate --force
  yarn build:production
  php artisan view:clear

  rm -f "/root/${THEME_NAME}.zip"
  rm -rf /root/pterodactyl

  echo -e "${GREEN}[+] INSTALLASI THEME BERHASIL [+]${NC}"
  sleep 2
  clear
}

# Versi bersih dari install_themeSteeler
install_themeSteeler() {
  echo -e "${BLUE}[+] INSTALL STELLAR THEME [+]${NC}"
  wget -q -O /root/stellar.zip https://github.com/veryLinh/Theme-Autoinstaller/raw/main/stellar.zip
  unzip -oq /root/stellar.zip -d /root/pterodactyl
  sudo cp -rfT /root/pterodactyl /var/www/pterodactyl

  curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt install -y nodejs
  sudo npm i -g yarn

  cd /var/www/pterodactyl || { echo -e "${RED}Direktori tidak ditemukan!${NC}"; return; }
  yarn add react-feather
  php artisan migrate --force
  yarn build:production
  php artisan view:clear

  sudo rm -f /root/stellar.zip
  sudo rm -rf /root/pterodactyl

  echo -e "${GREEN}[+] INSTALL SUCCESS [+]${NC}"
  sleep 2
  clear
}

# Create node (bersih)
create_node() {
  echo -e "${BLUE}[+] CREATE NODE [+]${NC}"
  read -p "Masukkan nama lokasi: " location_name
  read -p "Masukkan deskripsi lokasi: " location_description
  read -p "Masukkan domain: " domain
  read -p "Masukkan nama node: " node_name
  read -p "Masukkan RAM (dalam MB): " ram
  read -p "Masukkan jumlah maksimum disk space (dalam MB): " disk_space
  read -p "Masukkan Locid: " locid

  cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; return; }

  php artisan p:location:make <<EOF
$location_name
$location_description
EOF

  php artisan p:node:make <<EOF
$node_name
$location_description
$locid
https
$domain
yes
no
no
$ram
$ram
$disk_space
$disk_space
100
8080
2022
/var/lib/pterodactyl/volumes
EOF

  echo -e "${GREEN}[+] CREATE NODE & LOCATION SUKSES [+]${NC}"
  sleep 2
  clear
}

# Configure wings (lebih aman, tanpa eval)
configure_wings() {
  echo -e "${BLUE}[+] CONFIGURE WINGS [+]${NC}"
  read -p "Masukkan token Configure menjalankan wings: " wings_token

  # Simpan token ke file konfigurasi wings (contoh)
  sudo mkdir -p /etc/pterodactyl
  echo "$wings_token" | sudo tee /etc/pterodactyl/wings_token > /dev/null

  # restart service wings
  sudo systemctl restart wings

  echo -e "${GREEN}[+] CONFIGURE WINGS SUKSES [+]${NC}"
  sleep 2
  clear
}

# Lain-lain (uninstall, hackback, ubahpw)
uninstall_theme() {
  bash <(curl https://raw.githubusercontent.com/VallzHost/installer-theme/main/repair.sh)
  echo -e "${GREEN}[+] DELETE THEME SUKSES [+]${NC}"
  sleep 2
  clear
}

hackback_panel() {
  cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; return; }
  read -p "Masukkan Username Panel: " user
  read -p "Masukkan password login: " psswdhb

  php artisan p:user:make <<EOF
yes
hackback@gmail.com
$user
$user
$user
$psswdhb
EOF

  echo -e "${GREEN}[+] AKUN TELAH DI ADD [+]${NC}"
  sleep 2
  clear
}

ubahpw_vps() {
  read -p "Masukkan Pw Baru: " pw
  passwd <<EOF
$pw
$pw

EOF
  echo -e "${GREEN}[+] GANTI PW VPS SUKSES [+]${NC}"
  sleep 2
  clear
}

uninstall_panel() {
  bash <(curl -s https://pterodactyl-installer.se) <<EOF
y
y
y
y
EOF
  echo -e "${GREEN}[+] UNINSTALL PANEL SUKSES [+]${NC}"
  sleep 2
  clear
}

# Main script
display_welcome
install_jq
# NOTE: kita TIDAK memanggil check_token di awal, token hanya diminta bila diperlukan (mis. install_theme)

while true; do
  clear
  echo "BERIKUT LIST INSTALL :"
  echo "1. Install theme"
  echo "2. Uninstall theme"
  echo "3. Configure Wings"
  echo "4. Create Node"
  echo "5. Uninstall Panel"
  echo "6. Stellar Theme"
  echo "7. Hack Back Panel"
  echo "8. Ubah Pw Vps"
  echo "x. Exit"
  echo -ne "Masukkan pilihan 1/2/.../x: "
  read -r MENU_CHOICE
  clear

  case "$MENU_CHOICE" in
    1) install_theme ;;
    2) uninstall_theme ;;
    3) configure_wings ;;
    4) create_node ;;
    5) uninstall_panel ;;
    6) install_themeSteeler ;;
    7) hackback_panel ;;
    8) ubahpw_vps ;;
    x) echo "Keluar dari skrip."; exit 0 ;;
    *) echo "Pilihan tidak valid, silahkan coba lagi."; sleep 1 ;;
  esac
done
