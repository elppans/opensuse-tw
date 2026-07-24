#!/usr/bin/env bash

# Sair imediatamente se algum comando falhar
set -e

if command -v zypper; then
	# Definição dos pacotes divididos por categoria para organização
	PACOTES=(
		# Tema
		sound-theme-yaru
		kora-icon-theme
		# gnome-themes-extras
		dbus-launch

		# Suporte extensão
		gnome-shell-extension-user-theme
		gtk2-engine-murrine

		# Pacotes Devel
		git
		make

		# Pacotes Shell (--no-recommends tratado separadamente se necessário)
		jq
		ruby
		ShellCheck
		shfmt
		nodejs
		npm
	)

	echo "==> Atualizando repositórios e sistema..."
	sudo zypper --quiet --non-interactive refresh
	sudo zypper --non-interactive update

	echo "==> Instalando pacotes selecionados..."
	# Invocação única do zypper expandindo o array de pacotes
	sudo zypper -n install "${PACOTES[@]}"

	# Pacotes Shell (Global)
	sudo npm install --global prettier stylelint
elif command -v apt; then
	PACOTES=(
		# Tema
		yaru-theme-sound
		dbus-x11 # dbus-launch

		# Suporte extensão
		gnome-shell-extensions
		gnome-shell-extension-appindicator
		gtk2-engines-murrine

		# Pacotes Devel
		git
		make

		# Pacotes Shell*
		jq
		ruby
		shellcheck
		shfmt
		nodejs
		npm
		stylelint
	)

	echo "==> Atualizando repositórios e sistema..."
	sudo apt update
	sudo apt -y upgrade

	echo "==> Instalando pacotes selecionados..."
	sudo apt install "${PACOTES[@]}"
	
	# Pacotes Shell (Global)
	sudo npm install --global prettier
fi

mkdir -p ~/build && cd ~/build || exit 1
git clone https://github.com/elppans/archlinux-meta.git
cd archlinux-meta || exit 1
locdir="$(pwd)"
install="$locdir"
export install
base_install="$(basename "$install")"
export base_install

# Copiando alguns Custom Scripts do ArchLinux
# sudo cp -a "$install"/bin/wine /usr/local/bin
# sudo cp -a "$install"/bin/winetricks /usr/local/bin
# sudo cp -a "$install"/bin/flameshot /usr/local/bin
# sudo cp -a "$install"/bin/codium /usr/local/bin
# sudo cp -a "$install"/bin/codium-import.sh /usr/local/bin

cd "$install"/pacotes/ || exit 1
sed -i 's/flathub org.mozilla.firefox/# flathub org.mozilla.firefox/g' flatpak.list
./flatpak.sh
./flatpak.ini

cd "$install"/config/Gnome-Shell || exit 1
./gnome-shell-themes-orchis.sh # Instalação e configuração de temas
./gnome-shell-extensions.sh # Instalação e configuração de extensões
./gnome-shell-set.sh # Configurações do Gnome Shell+
./gnome-shell-build-xdg-directories.sh # Configuração e sincronização dos arquivos de diretórios XDG 
./gnome-shell-keyboard.sh # Configurações de atalhos do Gnome Shell+

cd "$install"/custom/ || exit 1
./file_templates.sh
./gnome-shell-headerbar.sh

# Definindo papel de parede
DIR_IMAGENS="$(xdg-user-dir PICTURES)"
git clone https://github.com/elppans/wallpapers-opensuse.git "$DIR_IMAGENS/Wallpapers"
gsettings set org.gnome.desktop.background picture-options 'spanned'
gsettings set org.gnome.desktop.background picture-uri "file://$DIR_IMAGENS/Wallpapers/opensuse-tumbleweed-gnome_1920x1080_001.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$DIR_IMAGENS/Wallpapers/opensuse-tumbleweed-gnome_1920x1080_001.jpg"

# Finalizando
echo -e 'build' >~/.hidden
sleep 5
sudo reboot
