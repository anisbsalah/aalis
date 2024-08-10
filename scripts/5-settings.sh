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
printf "[*] Dotfiles...\n"
cp -rf ~/aalis/settings/.config ~/
cp ~/aalis/settings/.face ~/
cp ~/aalis/settings/.bashrc ~/

printf "\n[*] Backgrounds...\n"
sudo mkdir -p /usr/share/backgrounds/AbS-Wallpapers
sudo cp ~/aalis/settings/backgrounds/* /usr/share/backgrounds/AbS-Wallpapers

printf "\n[*] Cursors...\n"
git clone https://github.com/anisbsalah/Catppuccin-Cursors.git /tmp/Catppuccin-Cursors &>/dev/null
sudo cp -rf /tmp/Catppuccin-Cursors/usr/share/icons/Catppuccin-Latte-Light-Cursors /usr/share/icons/
git clone https://github.com/anisbsalah/Qogir-Cursors.git /tmp/Qogir-Cursors &>/dev/null
sudo cp -rf /tmp/Qogir-Cursors/usr/share/icons/Qogir-Cursors /usr/share/icons/

printf "\n[*] Codium extensions...\n"
extensions=(
	"EditorConfig.EditorConfig"
	"esbenp.prettier-vscode"
	"foxundermoon.shell-format"
	"jeff-hykin.better-nix-syntax"
	"JohnnyMorganz.stylua"
	"mkhl.shfmt"
	"ph-hawkins.arc-plus"
	"PKief.material-icon-theme"
	"rogalmic.bash-debug"
	"timonwong.shellcheck"
	"trunk.io"
)

for ext in "${extensions[@]}"; do
	codium --install-extension "${ext}" --force
done

# ----------------------------------------------------------------------------------------------------

printf "\n[*] Path...\n"
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

printf "\n[*] Shells...\n"
echo 'export ZDOTDIR=${HOME}/.config/zsh' | sudo tee -a /etc/zsh/zshenv
sudo sed -i 's|HISTFILE=.*|HISTFILE="$HOME/.config/zsh/.zsh_history"|' /usr/share/oh-my-zsh/lib/history.zsh

# ----------------------------------------------------------------------------------------------------

printf "\n[*] Login manager settings...\n"
if [[ ${DESKTOP_ENV,,} == kde ]]; then

	SDDM_CONF="/etc/sddm.conf.d/kde_settings.conf"
	SDDM_THEME="breeze"
	SDDM_CURSOR_THEME="Breeze_Light"
	SDDM_FONT="Noto Sans,10,-1,0,400,0,0,0,0,0,0,0,0,0,0,1"
	SDDM_THEME_CONF="/usr/share/sddm/themes/${SDDM_THEME}/theme.conf.user"
	SDDM_BG="/usr/share/backgrounds/AbS-Wallpapers/sddm_bg.jpg"

	sudo mkdir -p /etc/sddm.conf.d
	sudo tee "${SDDM_CONF}" <<EOF
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=${SDDM_THEME}
CursorTheme=${SDDM_CURSOR_THEME}
Font=${SDDM_FONT}

[Users]
MaximumUid=60513
MinimumUid=1000
EOF

	sudo tee "${SDDM_THEME_CONF}" <<EOF
[General]
background=${SDDM_BG}
type=image
EOF

elif [[ ${DESKTOP_ENV,,} == cinnamon || ${DESKTOP_ENV,,} == xfce ]]; then

	LIGHTDM_CONF="/etc/lightdm/lightdm.conf"
	LIGHTDM_GREETER_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
	LIGHTDM_GTK_THEME="Arc-Dark"
	LIGHTDM_ICON_THEME="Papirus-Dark"
	LIGHTDM_CURSOR_THEME="Qogir-Cursors"
	LIGHTDM_CURSOR_SIZE="24"
	LIGHTDM_FONT="Noto Sans Bold 11"
	LIGHTDM_BG="/usr/share/backgrounds/AbS-Wallpapers/lightdm-gtk_bg.jpg"
	LIGHTDM_AVATAR="/usr/share/backgrounds/AbS-Wallpapers/avatar.png"

	FIND='[#[:space:]]*greeter-session=.*'
	REPLACE='greeter-session=lightdm-gtk-greeter'
	sudo sed -i "s/${FIND}/${REPLACE}/g" "${LIGHTDM_CONF}"

	sudo tee "${LIGHTDM_GREETER_CONF}" <<EOF
[greeter]
theme-name = ${LIGHTDM_GTK_THEME}
icon-theme-name = ${LIGHTDM_ICON_THEME}
cursor-theme-name = ${LIGHTDM_CURSOR_THEME}
cursor-theme-size = ${LIGHTDM_CURSOR_SIZE}
font-name = ${LIGHTDM_FONT}
user-background = false
background = ${LIGHTDM_BG}
default-user-image = ${LIGHTDM_AVATAR}
EOF

fi

# ----------------------------------------------------------------------------------------------------
#
# Specefic desktop settings
#
# ----------------------------------------------------------------------------------------------------

DESKTOP_BG="/usr/share/backgrounds/AbS-Wallpapers/desktop_bg.jpg"
LOOKANDFEEL="org.kde.breezedark.desktop"
COLORSCHEME="ArcDark"
DESKTOPTHEME="Arc-Dark"
GTK_THEME="Arc-Dark"
ICON_THEME="Papirus-Dark"
CURSOR_THEME="Breeze_Light"
CURSOR_SIZE="24"
SOUND_THEME="ocean"

if [[ ${DESKTOP_ENV,,} == kde ]]; then

	# --------------------------------------------------

	printf "\n[*] Installing Plasma dotfiles...\n"
	cp -rf ~/aalis/settings/plasma/.config ~/
	cp -rf ~/aalis/settings/plasma/.local ~/
	sudo cp -rf ~/aalis/settings/plasma/usr /

	# -------------------------------------------------

	printf "\n[*] Setting system fonts...\n"
	kwriteconfig6 --file kdeglobals --group "General" --key "font" "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group "General" --key "fixed" "Hack,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group "General" --key "smallestReadableFont" "Noto Sans,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group "General" --key "toolBarFont" "Noto Sans,10,-1,5,50,0,0,0,0,0"
	kwriteconfig6 --file kdeglobals --group "General" --key "menuFont" "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group "WM" --key "activeFont" "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
	kwriteconfig6 --file kdeglobals --group "General" --key "XftAntialias" "true"
	kwriteconfig6 --file kdeglobals --group "General" --key "XftHintStyle" "hintslight"
	kwriteconfig6 --file kdeglobals --group "General" --key "XftSubPixel" "rgb"

	# -------------------------------------------------

	printf "\n[*] Setting colors and themes...\n"

	# Global theme
	kwriteconfig6 --file kdeglobals --group "KDE" --key "LookAndFeelPackage" "${LOOKANDFEEL}"
	sudo kwriteconfig6 --file kdeglobals --group "KDE" --key "LookAndFeelPackage" "${LOOKANDFEEL}"

	# Colors
	kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "${COLORSCHEME}"
	sudo kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "${COLORSCHEME}"

	# Night Light
	kwriteconfig6 --file kwinrc --group "NightColor" --key "Active" "true"
	sudo kwriteconfig6 --file kwinrc --group "NightColor" --key "Active" "true"

	# Application Style
	kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "kvantum"
	sudo kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "kvantum"

	# Plasma Style
	kwriteconfig6 --file plasmarc --group "Theme" --key "name" "${DESKTOPTHEME}"
	sudo kwriteconfig6 --file plasmarc --group "Theme" --key "name" "${DESKTOPTHEME}"

	# Window Decorations
	kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae"
	sudo kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae"

	kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Arc-Dark"
	sudo kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Arc-Dark"

	# Icons
	kwriteconfig6 --file kdeglobals --group "Icons" --key "Theme" "${ICON_THEME}"
	sudo kwriteconfig6 --file kdeglobals --group "Icons" --key "Theme" "${ICON_THEME}"

	# Cursors
	kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorTheme" "${CURSOR_THEME}"
	sudo kwriteconfig6 --file kcminputrc --group "Mouse" --key "cursorTheme" "${CURSOR_THEME}"

	# System Sounds
	kwriteconfig6 --file kdeglobals --group "Sounds" --key "Theme" "${SOUND_THEME}"
	sudo kwriteconfig6 --file kdeglobals --group "Sounds" --key "Theme" "${SOUND_THEME}"

	# Splash Screen
	kwriteconfig6 --file ksplashrc --group "KSplash" --key "Engine" "none"
	sudo kwriteconfig6 --file ksplashrc --group "KSplash" --key "Engine" "none"

	kwriteconfig6 --file ksplashrc --group "KSplash" --key "Theme" "None"
	sudo kwriteconfig6 --file ksplashrc --group "KSplash" --key "Theme" "None"

	# -------------------------------------------------

	printf "\n[*] Setting dark GTK...\n"
	function set_dark_gtk {
		local gtk3_settings=~/.config/gtk-3.0/settings.ini
		local gtk4_settings=~/.config/gtk-4.0/settings.ini
		GTK_SETTINGS=("${gtk3_settings}" "${gtk4_settings}")

		for gtk_settings in "${GTK_SETTINGS[@]}"; do
			mkdir -p "$(dirname "${gtk_settings}")"

			cat >"${gtk_settings}" <<EOF
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=${GTK_THEME}
gtk-icon-theme-name=${ICON_THEME}
gtk-cursor-theme-name=${CURSOR_THEME}
gtk-cursor-theme-size=${CURSOR_SIZE}
gtk-font-name=Noto Sans,  10
gtk-modules=colorreload-gtk-module
gtk-sound-theme-name=${SOUND_THEME}
EOF
		done
	}

	set_dark_gtk

	# -------------------------------------------------

	printf "\n[*] Setting wallpaper...\n"

	sudo tee /usr/local/bin/set-wallpaper.sh <<EOF
#!/bin/bash
plasma-apply-wallpaperimage ${DESKTOP_BG}
EOF

	sudo chmod +x /usr/local/bin/set-wallpaper.sh

	mkdir -p ~/.config/autostart

	tee ~/.config/autostart/set-wallpaper.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/set-wallpaper.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set Wallpaper
Comment=Sets the wallpaper at startup
EOF

	# -------------------------------------------------

	printf "\n[*] Setting screen locking appearance...\n"
	LOCK_IMAGE="/usr/share/backgrounds/AbS-Wallpapers/sddm_bg.jpg"
	LOCK_PRVIEWIMAGE="/usr/share/backgrounds/AbS-Wallpapers/sddm_bg.jpg"
	kwriteconfig6 --file kscreenlockerrc --group "Greeter" --group "Wallpaper" --group "org.kde.image" --group "General" --key "Image" "${LOCK_IMAGE}"
	kwriteconfig6 --file kscreenlockerrc --group "Greeter" --group "Wallpaper" --group "org.kde.image" --group "General" --key "PreviewImage" "${LOCK_PRVIEWIMAGE}"

	# -------------------------------------------------

	printf "\n[*] Setting services to be shown in the context menu...\n"
	kwriteconfig6 --file kservicemenurc --group "Show" --key OpenAsRootKDE5 true
	kwriteconfig6 --file kservicemenurc --group "Show" --key compressfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key diff false
	kwriteconfig6 --file kservicemenurc --group "Show" --key diffsudo false
	kwriteconfig6 --file kservicemenurc --group "Show" --key extractfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key forgetfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key installFont true
	kwriteconfig6 --file kservicemenurc --group "Show" --key kactivitymanagerd_fileitem_linking_plugin true
	kwriteconfig6 --file kservicemenurc --group "Show" --key kdeconnectfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key kompare false
	kwriteconfig6 --file kservicemenurc --group "Show" --key makefileactions true
	kwriteconfig6 --file kservicemenurc --group "Show" --key mountisoaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key plasmavaultfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key runInKonsole false
	kwriteconfig6 --file kservicemenurc --group "Show" --key selected true
	kwriteconfig6 --file kservicemenurc --group "Show" --key selectedsudo true
	kwriteconfig6 --file kservicemenurc --group "Show" --key setArg1 false
	kwriteconfig6 --file kservicemenurc --group "Show" --key sharefileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key slideshowfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key tagsfileitemaction true
	kwriteconfig6 --file kservicemenurc --group "Show" --key wallpaperfileitemaction true

	# -------------------------------------------------

	printf "\n[*] Setting keyboard layout...\n"
	kwriteconfig6 --file kxkbrc --group "Layout" --key "DisplayNames" ","
	kwriteconfig6 --file kxkbrc --group "Layout" --key "LayoutList" "fr,ara"
	kwriteconfig6 --file kxkbrc --group "Layout" --key "Options" "grp:win_space_toggle"
	kwriteconfig6 --file kxkbrc --group "Layout" --key "ResetOldOptions" "true"
	kwriteconfig6 --file kxkbrc --group "Layout" --key "Use" "true"
	kwriteconfig6 --file kxkbrc --group "Layout" --key "VariantList" ",azerty"

	# -------------------------------------------------

	printf "\n[*] Setting touchpad options...\n"
	kwriteconfig6 --file touchpadxlibinputrc --group "AlpsPS/2 ALPS GlidePoint" --key "scrollEdge" "true"
	kwriteconfig6 --file touchpadxlibinputrc --group "AlpsPS/2 ALPS GlidePoint" --key "scrollTwoFinger" "false"
	kwriteconfig6 --file touchpadxlibinputrc --group "AlpsPS/2 ALPS GlidePoint" --key "tapToClick" "true"

	# -------------------------------------------------

	printf "\n[*] Setting default applications...\n"
	kwriteconfig6 --file kdeglobals --group "General" --key "BrowserApplication" "brave-browser.desktop"
	kwriteconfig6 --file kdeglobals --group "General" --key "TerminalApplication" "alacritty"
	kwriteconfig6 --file kdeglobals --group "General" --key "TerminalService" "Alacritty.desktop"

	# -------------------------------------------------

	printf "\n[*] Setting application settings...\n"
	kwriteconfig6 --file yakuakerc --group "Appearance" --key "Skin" "arc-dark"
	kwriteconfig6 --file yakuakerc --group "Dialogs" --key "FirstRun" false
	kwriteconfig6 --file yakuakerc --group "Window" --key "KeepAbove" false

	kwriteconfig6 --file konsolerc --group "Desktop Entry" --key "DefaultProfile" "AbS.profile"
	kwriteconfig6 --file konsolerc --group "General" --key "ConfigVersion" 1
	kwriteconfig6 --file konsolerc --group "MainWindow" --key "MenuBar" Disabled
	kwriteconfig6 --file konsolerc --group "MainWindow" --key "ToolBarsMovable" Disabled

	# --------------------------------------------------

fi

# ----------------------------------------------------------------------------------------------------

echo "
================================================================================

                       SYSTEM READY FOR 6-post-install.sh

================================================================================
"
sleep 1
clear
exit 0
