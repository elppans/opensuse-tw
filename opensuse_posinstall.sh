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

echo "Preparando pacote meta para uso no sistema"
sleep 5
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

echo "Finalizando a instalação verificando atualização de pacotes"
sleep 5
sudo flatpak --noninteractive -y update
sudo zypper --non-interactive update

echo "Fazendo limpeza no sistema após instalação de pacotes"
sleep 5
sudo zypper clean -a # Limpa todos os caches de repositórios e pacotes baixados (.rpm).
sudo zypper clean # Limpa apenas os metadados e arquivos temporários expirados/antigos.
sudo zypper packages --unneeded | awk -F'|' 'NR>4 {print $3}' | xargs sudo zypper rm -u &>>/dev/null # Remover todos os órfãos em massa
sudo flatpak uninstall --unused &>>/dev/null # Limpeza de Runtimes/Apps sem uso no escopo do SISTEMA (sudo)
flatpak uninstall --unused --user # Limpeza de Runtimes/Apps sem uso no escopo de USUÁRIO
rm -rf ~/.cache/flatpak/ # O Flatpak não possui um subcomando nativo clean; os arquivos baixados temporários ficam na cache de usuário.
sudo rm -rf /var/tmp/flatpak-cache-* # Limpeza de Arquivos Temporários de Download no /var
sudo flatpak repair # Se houver objetos órfãos ou inconsistências no repositório local OSTree do Flatpak.

sleep 5
sudo reboot

