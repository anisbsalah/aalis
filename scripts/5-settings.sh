#!/usr/bin/env bash
#
# @file Settings
# @brief Installs personal dotfiles and settings.

echo "
================================================================================
    █████╗ ██████╗  ██████╗██╗  ██╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
   ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
   ███████║██████╔╝██║     ███████║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
   ██╔══██║██╔══██╗██║     ██╔══██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ 
   ██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
================================================================================
                    Automated Arch Linux Installation Script
================================================================================
"
echo ":: sourcing '${HOME}/aalis/setup.conf'..."
source "${HOME}/aalis/setup.conf"

echo "
================================================================================
 Installing personal settings
================================================================================
"
echo "[*] Dotfiles..."
cp -r ~/aalis/settings/.config/* ~/.config/
cp ~/aalis/settings/.face ~/

# ----------------------------------------------------------------------------------------------------

echo "[*] Backgrounds..."
sudo mkdir -p /usr/share/backgrounds/AbS-Wallpapers
sudo cp ~/aalis/settings/backgrounds/* /usr/share/backgrounds/AbS-Wallpapers

# ----------------------------------------------------------------------------------------------------

echo "[*] Cursors..."
git clone https://github.com/anisbsalah/Catppuccin-Cursors.git /tmp/Catppuccin-Cursors
sudo cp -rf /tmp/Catppuccin-Cursors/usr/share/icons/Catppuccin-Latte-Light-Cursors /usr/share/icons/

# ----------------------------------------------------------------------------------------------------

if [[ ${DESKTOP_ENV} == cinnamon || ${DESKTOP_ENV} == xfce ]]; then
	echo "[*] Lightdm settings..."
	FIND='[#[:space:]]*greeter-session=.*'
	REPLACE='greeter-session=lightdm-gtk-greeter'
	sudo sed -i "s/${FIND}/${REPLACE}/g" /etc/lightdm/lightdm.conf

	sudo tee "/etc/lightdm/lightdm-gtk-greeter.conf" <<EOF
[greeter]
theme-name = Arc-Dark
icon-theme-name = Papirus-Dark
cursor-theme-name = Catppuccin-Latte-Light-Cursors
cursor-theme-size = 24
font-name = Noto Sans Bold 11
background = /usr/share/backgrounds/AbS-Wallpapers/lightdm-gtk_bg.jpg
default-user-image = /usr/share/backgrounds/AbS-Wallpapers/avatar.png
EOF
fi

# ----------------------------------------------------------------------------------------------------

echo "[*] Path..."
# shellcheck disable=SC2016
echo '
set_path() {

	# Check if user id is 1000 or higher
	[[ "$(id -u)" -ge 1000 ]] || return

	for i in "$@"; do
		# Check if the directory exists
		[[ -d ${i} ]] || continue

		# Check if it is not already in your $PATH.
		echo "${PATH}" | grep -Eq "(^|:)${i}(:|$)" && continue

		# Then append it to $PATH and export it
		export PATH="${PATH}:${i}"
	done
}

set_path ~/bin ~/scripts ~/.local/bin' | sudo tee -a /etc/profile

# ----------------------------------------------------------------------------------------------------

echo "
================================================================================

                       SYSTEM READY FOR 6-post-install.sh

================================================================================
"
sleep 1
clear
exit 0
