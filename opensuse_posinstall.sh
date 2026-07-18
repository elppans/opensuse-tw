#!/usr/bin/env bash

if command -v zypper ; then
	sudo zypper --non-interactive refresh
	sudo zypper -n install sound-theme-yaru kora-icon-theme # Tema 
	sudo zypper -n install caffeine-guava gnome-themes-extras gtk2-engine-murrine # Suporte extensão
	sudo zypper -n install git make # Pacotes Devel
	sudo zypper -n install --no-recommends jq ruby ShellCheck shfmt nodejs npm # Pacotes Shell
elif command -v apt ; then
        apt update
fi

sudo npm install -g prettier stylelint # Pacotes Shell (Global)

mkdir -p ~/build

cd ~/build || exit 1 
git clone https://github.com/elppans/Orchis-theme.git
cd ~/build/Orchis-theme || exit 1
./install.sh -c dark -l -f  -i opensuse --tweaks compact dock # primary = barra flutuante
sudo flatpak override --filesystem=xdg-config/gtk-3.0 && sudo flatpak override --filesystem=xdg-config/gtk-4.0

mkdir -p ~/build/bibata-cursor-theme && cd ~/build/bibata-cursor-theme || exit 1
curl -JOLk https://github.com/elppans/Bibata_Cursor/releases/download/v2.0.7/Bibata.tar.xz
sudo mkdir -p /etc/skel/.local/share/icons/
sudo tar -xJf Bibata.tar.xz -C /etc/skel/.local/share/icons/
rsync -ah /etc/skel/. "$HOME/"

mkdir -p ~/build/gnome-shell-extension-appindicator && cd ~/build/gnome-shell-extension-appindicator  || exit 1
curl -JOLk "https://github.com/ubuntu/gnome-shell-extension-appindicator/releases/download/v64/appindicatorsupport@rgcjonas.gmail.com.zip"
gnome-extensions install appindicatorsupport@rgcjonas.gmail.com.zip

# https://github.com/eonpatapon/gnome-shell-extension-caffeine
mkdir -p ~/build/gnome-shell-extension-caffeine && cd ~/build/gnome-shell-extension-caffeine  || exit 1
curl -JOLk "https://github.com/elppans/gnome-shell-extension-caffeine/releases/download/v60/caffeine@patapon.info.zip"
gnome-extensions install caffeine@patapon.info.zip
gsettings --schemadir ~/.local/share/gnome-shell/extensions/caffeine@patapon.info/schemas/ get org.gnome.shell.extensions.caffeine cli-toggle # status
gsettings --schemadir ~/.local/share/gnome-shell/extensions/caffeine@patapon.info/schemas/ set org.gnome.shell.extensions.caffeine cli-toggle true # Enable/Disable

# Ativar as 3 extensões instaladas
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'caffeine@patapon.info', 'appindicatorsupport@rgcjonas.gmail.com']"

cd ~/build || exit 1
git clone https://github.com/elppans/archlinux-meta.git

cd ~/build/archlinux-meta/config/Gnome-Shell || exit 1
./gnome-shell-set.sh 
./gnome-shell-keyboard.sh

cd ~/build/archlinux-meta/custom/ || exit 1
./file_templates.sh
./gnome-shell-headerbar.sh

cd ~/build/archlinux-meta/pacotes/ || exit 1
sed -i 's/flathub org.mozilla.firefox/# flathub org.mozilla.firefox/g' flatpak.list
./flatpak.sh
./flatpak.ini 

sudo cp -a ~/build/archlinux-meta/bin/wine /usr/local/bin
sudo cp -a ~/build/archlinux-meta/bin/winetricks /usr/local/bin
sudo cp -a ~/build/archlinux-meta/bin/flameshot /usr/local/bin
sudo cp -a ~/build/archlinux-meta/bin/codium /usr/local/bin
sudo cp -a ~/build/archlinux-meta/bin/codium-import.sh /usr/local/bin

# Definindo papel de parede
DIR_IMAGENS="$(xdg-user-dir PICTURES)"
git clone https://github.com/elppans/wallpapers-opensuse.git "$DIR_IMAGENS/Wallpapers"
gsettings set org.gnome.desktop.background picture-options 'spanned'
gsettings set org.gnome.desktop.background picture-uri "file://$DIR_IMAGENS/Wallpapers/opensuse-tumbleweed-gnome_1920x1080_001.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$DIR_IMAGENS/Wallpapers/opensuse-tumbleweed-gnome_1920x1080_001.jpg"

# Finalizando
echo -e 'build' > ~/.hidden
sleep 5
sudo reboot
