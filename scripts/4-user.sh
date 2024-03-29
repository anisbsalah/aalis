#!/usr/bin/env bash
#
# @file User
# @brief Installs pacman packages, desktop environment, AUR packages and flatpak.

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
cd ~ || exit 1

echo "
================================================================================
 Installing 'pacman' packages
================================================================================"

while read -r line; do
	if [[ ${line} =~ '# ---' ]]; then
		continue
	fi
	printf "\n[*] INSTALLING: %s\n\n" "${line}"
	sudo pacman -S --noconfirm --needed "${line}"
done < <(sed -n "/END OF ${INSTALL_TYPE^^} INSTALLATION/q;p" "${HOME}/aalis/pkg-files/pacman-pkgs.txt")

# ----------------------------------------------------------------------------------------------------

echo "
================================================================================
 Installing ${DESKTOP_ENV^^} desktop environment
================================================================================"

while read -r line; do
	if [[ ${line} =~ '# ---' ]]; then
		continue
	fi
	printf "\n[*] INSTALLING: %s\n\n" "${line}"
	sudo pacman -S --noconfirm --needed "${line}"
done < <(sed -n "/END OF ${INSTALL_TYPE^^} INSTALLATION/q;p" "${HOME}/aalis/pkg-files/${DESKTOP_ENV}.txt")

echo "
================================================================================
 Enabling login display manager
================================================================================
"
case ${DESKTOP_ENV} in
"cinnamon" | "xfce") sudo systemctl enable lightdm.service ;;
"gnome") sudo systemctl enable gdm.service ;;
"kde") sudo systemctl enable sddm.service ;;
*) ;;
esac

# ----------------------------------------------------------------------------------------------------

echo "
================================================================================
 Adding the ArcoLinux repositories
================================================================================
"
echo "[*] Getting the ArcoLinux keys..."
echo
sudo wget https://github.com/arcolinux/arcolinux_repo/raw/main/x86_64/arcolinux-keyring-20251209-3-any.pkg.tar.zst -O /tmp/arcolinux-keyring-20251209-3-any.pkg.tar.zst
sudo pacman -U --noconfirm --needed /tmp/arcolinux-keyring-20251209-3-any.pkg.tar.zst
echo
echo "[*] Getting the latest ArcoLinux mirrors file..."
echo
sudo wget https://github.com/arcolinux/arcolinux_repo/raw/main/x86_64/arcolinux-mirrorlist-git-23.06-01-any.pkg.tar.zst -O /tmp/arcolinux-mirrorlist-git-23.06-01-any.pkg.tar.zst
sudo pacman -U --noconfirm --needed /tmp/arcolinux-mirrorlist-git-23.06-01-any.pkg.tar.zst
echo '

#[arcolinux_repo_testing]
#SigLevel = PackageRequired DatabaseNever
#Include = /etc/pacman.d/arcolinux-mirrorlist

[arcolinux_repo]
SigLevel = PackageRequired DatabaseNever
Include = /etc/pacman.d/arcolinux-mirrorlist

[arcolinux_repo_3party]
SigLevel = PackageRequired DatabaseNever
Include = /etc/pacman.d/arcolinux-mirrorlist

[arcolinux_repo_xlarge]
SigLevel = PackageRequired DatabaseNever
Include = /etc/pacman.d/arcolinux-mirrorlist' | sudo tee --append /etc/pacman.conf

echo
echo "[*] Updating database..."
sudo pacman -Sy

# ----------------------------------------------------------------------------------------------------

if [[ ${AUR_HELPER} != none ]]; then
	echo "
================================================================================
 Installing AUR helper: '${AUR_HELPER}'
================================================================================
"
	cd ~ || exit 1
	git clone "https://aur.archlinux.org/${AUR_HELPER}.git"
	(cd ~/"${AUR_HELPER}" && makepkg -si --noconfirm --needed)
	rm -rf "${AUR_HELPER}"

	case ${AUR_HELPER} in
	"yay" | "yay-bin")
		aur_command="yay"
		;;
	"paru" | "paru-bin")
		aur_command="paru"
		;;
	"trizen")
		aur_command="trizen"
		;;
	"pikaur")
		aur_command="pikaur"
		;;
	"pakku")
		aur_command="pakku"
		;;
	"aurman")
		aur_command="aurman"
		;;
	"aura")
		aur_command="sudo aura"
		;;
	*) ;;
	esac

	echo "
================================================================================
 Installing AUR packages
================================================================================"

	while read -r line; do
		if [[ ${line} =~ '# ---' ]]; then
			if [[ ${line} =~ 'specific software' ]]; then
				break
			fi
			continue
		fi
		printf "\n[*] INSTALLING: %s\n\n" "${line}"
		"${aur_command}" -S --noconfirm --needed "${line}"
	done < <(sed -n "/END OF ${INSTALL_TYPE^^} INSTALLATION/q;p" "$HOME/aalis/pkg-files/aur-pkgs.txt")

	# Installing specific AUR software for selected desktop
	specific_software_found=false
	while read -r line; do
		if [[ ${line} == *"${DESKTOP_ENV^^} specific software"* ]]; then
			specific_software_found=true
			continue
		fi

		if [[ ${specific_software_found} == true ]]; then
			if [[ ${line} =~ 'specific software' ]]; then
				break
			fi
			printf "\n[*] INSTALLING: %s\n\n" "${line}"
			"${aur_command}" -S --noconfirm --needed "${line}"
		fi
	done < <(sed -n "/END OF ${INSTALL_TYPE^^} INSTALLATION/q;p" "$HOME/aalis/pkg-files/aur-pkgs.txt")

fi

# ----------------------------------------------------------------------------------------------------

if [[ ${FLATPAK} == true ]]; then
	echo "
================================================================================
 Installing flatpak packages
================================================================================
"
	sudo pacman -S --noconfirm --needed flatpak
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# ----------------------------------------------------------------------------------------------------

echo "
================================================================================

                         SYSTEM READY FOR 5-settings.sh

================================================================================
"
sleep 1
clear
exit 0
