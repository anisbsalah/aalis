#!/usr/bin/env bash
#
# @file AALIS
# @brief Entrance script that launches children scripts for each phase of installation.

# Find the name of the project folder
set -a
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
set +a

# Set console font
setfont ter-v20b

# Update system clock
timedatectl set-ntp true

clear

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
echo "
================================================================================
 Installing prerequisites
================================================================================
"
sed -i 's/^[#[:space:]]*ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
sed -i 's/^[#[:space:]]*Color/Color\nILoveCandy/' /etc/pacman.conf

pacman -Sy
pacman -S --noconfirm archlinux-keyring # Update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed arch-install-scripts glibc
pacman -S --noconfirm --needed gptfdisk btrfs-progs
pacman -S --noconfirm --needed curl libnewt reflector rsync wget

clear

# ----------------------------------------------------------------------------------------------------

CONFIG_FILE="${PROJECT_DIR}/setup.conf"
if [[ ! -f ${CONFIG_FILE} ]]; then # check if file exists
	touch -f "${CONFIG_FILE}"         # create file if not exists
fi

# ----------------------------------------------------------------------------------------------------

root_check() {
	if [[ "$(id -u)" != "0" ]]; then
		echo "ERROR! This script must be run under the 'root' user."
		exit 0
	fi
}

docker_check() {
	if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
		echo "ERROR! Docker container is not supported (at the moment)"
		exit 0
	elif [[ -f /.dockerenv ]]; then
		echo "ERROR! Docker container is not supported (at the moment)"
		exit 0
	fi
}

arch_check() {
	if [[ ! -e /etc/arch-release ]]; then
		echo "ERROR! This script must be run in Arch Linux."
		exit 0
	fi
}

pacman_check() {
	if [[ -f /var/lib/pacman/db.lck ]]; then
		echo "ERROR! Pacman is blocked."
		echo "If not running, remove: /var/lib/pacman/db.lck"
		exit 0
	fi
}

background_checks() {
	root_check
	arch_check
	pacman_check
	docker_check
}

# ----------------------------------------------------------------------------------------------------

set_option() {
	if grep -Eq "^${1}.*" "${CONFIG_FILE}"; then # check if option exists
		sed -i -e "/^${1}.*/d" "${CONFIG_FILE}"     # delete option if exists
	fi
	echo "${1}=${2}" >>"${CONFIG_FILE}" # add option
}

del_option() {
	if grep -Eq ".*${1}.*" "${CONFIG_FILE}"; then # check if option exists
		sed -i -e "/.*${1}.*/d" "${CONFIG_FILE}"     # delete option if exists
	fi
}

# ----------------------------------------------------------------------------------------------------

load_strings() {
	apptitle="Arch Linux Install Script"
	txtwelcome="Welcome"
	txtmainmenu="Main menu"
	txtexit="Exit"
	txtback="Back"
	txtconfirm="Confirm"
	txtwarning="Warning!"
	txterror="ERROR!"
	txttimezone="Timezone"
	txtselectzone="Select your timezone:\n(Default: Africa/Tunis)"
	txtlocale="Locale"
	txtselectlocales="Select the desired locales to generate:\n(Default: en_US)"
	txtkeymap="Keymap"
	txtselectkeyboard="Select your keyboard layout:\n(Default: us)"
	txtconsolefont="Consolefont"
	txtselectvcfont="Select your desired consolefont:\n(Default: ter-v20b)"
	txtdiskpartmenu="Disks & Partitions"
	txtbootmode="Boot Mode"
	txtbootmodemsg="The system is booted in %1 mode."
	txtselectdisk="Select Disk"
	txtaskdiskssd="Is %1 a SSD?"
	txtaskdiskselection="Select the disk device you want to install Arch Linux on:"
	txtconfirmselecteddevice="Selected device: %1 ?"
	txtconfirmwipedata="Are you sure you want to wipe all data on %1 ?"
	txtdiskdevice="Disk Device"
	txtselecteddiskstatus="Selected Disk Status"
	txtconfirmformatpartitions="Do you want to proceed with formatting the partitions?"
	txtpartitiontable="Partition Table"
	txtdeletepartitiontable="Do you want to delete the partition table and create a new one?"
	txtautoparts="Auto Partitions"
	txtmanualparts="Manual Partitions"
	txtselectpartitionscheme="Select your desired partition scheme:"
	txtformatpartitions="Format Partitions"
	txtpartitionslist="Partitions List"
	txtpartitioninglayout="Partitioning Layout"
	txtmountpoint="Mount Point"
	txtfilesystem="Filesystem"
	txtselectfilesystem="Select the appropriate filesystem for %1 partition:"
	txtfilesystempkgs="Select additional filesystem packages to install (if needed):"
	txtbtrfssubvolumes="Btrfs Subvolumes"
	txtentersubvolnames="Enter a name for the subvolume to create:\n(leave blank to finish)"
	txtentersubvolmntpts="Enter the corresponding mountpoint for subvolume"
	txtswap="Swap"
	txtaskswapsize="Type the size of the swap partition (MiB):"
	txtswapfile="Swap File"
	txtaskswapfile="Do you want to create a swap file?"
	txtswapfilesize="Type the size of the swap file (MiB):"
	txtusersmenu="Users Menu"
	txtsethostname="Set Hostname"
	txtsetusername="Set Username"
	txtaskpassword="%1 password:"
	txtsetpassword="Set %1 Password"
	txtpassword="%1 Password"
	txtinstallmenu="Installation Menu"
	txtkernel="Kernel"
	txtselectkernel="Select the appropriate kernel to install:"
	txtdesktopenv="Desktop Environment"
	txtselectdesktopenv="Select your desired Desktop Environment:"
	txtinstalltype="Installation Type"
	txtselectinstalltype="Full or Minimal?"
	txtaurhelper="AUR Helper"
	txtselectaurhelper="Select your desired AUR helper:"
	txtflatpak="Flatpak"
	txtinstallflatpak="Do you want to install flatpak?"
	txtsummary="Summary"
	txtconfigfile="setup.conf"
	txtinstallarch="Install Arch Linux"
	txtreboot="Reboot"
	txtquit="Are you sure you want to quit?"
}

# ----------------------------------------------------------------------------------------------------

welcome() {
	message="Welcome to the Arch Linux Installation Script!

This script will guide you through the process of installing Arch Linux on your system. It provides a user-friendly menu where you can select various settings and options based on your preferences.

Please take a moment to go through the menu and make the desired selections.

Once you have made all the necessary selections, the script will proceed with the automated installation process. It will partition the disk, install the base system, install the desktop environment, set up the bootloader, and configure the system according to your chosen settings.

Please note that this script assumes you have a basic understanding of the installation process and that you have made any necessary backups of your data. If you are unsure about any step, refer to the Arch Linux documentation for detailed instructions.

Let's begin the installation process and set up your Arch Linux system. Enjoy the power and flexibility of Arch Linux!"
	whiptail --backtitle "${apptitle}" --title "${txtwelcome}" \
		--msgbox "${message}" 26 85
}

# ----------------------------------------------------------------------------------------------------

mainmenu() {
	if [[ ${1} == "" ]]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txttimezone}" "")
	options+=("${txtlocale}" "")
	options+=("${txtkeymap}" "")
	options+=("${txtconsolefont}" "")
	options+=("${txtdiskpartmenu}" "")
	options+=("${txtusersmenu}" "")
	options+=("${txtinstallmenu}" "")
	options+=("${txtsummary}" "")
	options+=("${txtinstallarch}" "")
	options+=("" "")
	options+=("${txtreboot}" "")

	if menupick=$(whiptail --backtitle "${apptitle}" --title "${txtmainmenu}" \
		--cancel-button "${txtexit}" --default-item "${nextitem}" \
		--menu "Please select the desired settings for your system:" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		case ${menupick} in
		"${txttimezone}")
			set_timezone
			nextitem="${txtlocale}"
			;;
		"${txtlocale}")
			set_locale
			nextitem="${txtkeymap}"
			;;
		"${txtkeymap}")
			set_keymap
			nextitem="${txtconsolefont}"
			;;
		"${txtconsolefont}")
			set_consolefont
			nextitem="${txtdiskpartmenu}"
			;;
		"${txtdiskpartmenu}")
			boot_mode
			diskpartmenu
			nextitem="${txtusersmenu}"
			;;
		"${txtusersmenu}")
			usersmenu
			nextitem="${txtinstallmenu}"
			;;
		"${txtinstallmenu}")
			installmenu
			nextitem="${txtsummary}"
			;;
		"${txtsummary}")
			summary
			nextitem="${txtinstallarch}"
			;;
		"${txtinstallarch}")
			if install_arch; then
				return 0
			else
				mainmenu "${txtinstallarch}"
			fi
			;;
		"${txtreboot}")
			reboot_pc
			nextitem="${txtreboot}"
			;;
		*) ;;
		esac
		mainmenu "${nextitem}"
	else
		if (whiptail --backtitle "${apptitle}" --title "${txtexit}" \
			--defaultno --yesno "${txtquit}" 7 34); then

			clear
			exit 0
		else
			mainmenu "${nextitem}"
		fi
	fi
}

# ----------------------------------------------------------------------------------------------------

default_values() {
	set_option "TIMEZONE" "Africa/Tunis"
	set_option "LOCALES" "(en_US)"
	set_option "KEYMAP" "us"
	set_option "CONSOLEFONT" "ter-v20b"
}

# ----------------------------------------------------------------------------------------------------

reboot_pc() {
	if (whiptail --backtitle "${apptitle}" --title "${txtreboot}" \
		--defaultno --yesno "Do you want to reboot now?" 7 30); then

		umount -R /mnt
		clear
		reboot
	fi
}

# ----------------------------------------------------------------------------------------------------

detect_timezone() {
	server='http://geoip.ubuntu.com/lookup'
	if ping -c3 "${server}" 2>/dev/null; then
		TIMEZONE=$(wget -O - -q http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p')
	fi
	# See arch wiki https://wiki.archlinux.org/title/System_time
	#TIMEZONE="$(curl --fail https://ipapi.co/timezone)"

	# Default timezone is Africa/Tunis (we will use detect_timezone value if geoip site is up)
	TIMEZONE=${TIMEZONE:='Africa/Tunis'}
}

set_timezone() {
	detect_timezone
	timezones=$(timedatectl list-timezones)
	options=()
	for item in ${timezones}; do
		options+=("${item}" "")
	done

	if timezone=$(whiptail --backtitle "${apptitle}" --title "${txttimezone}" \
		--default-item "${nextitem}" --menu "${txtselectzone}" 30 45 22 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		set_option "TIMEZONE" "${timezone}"

	else
		msg="No timezone selected.\nDefault: ${TIMEZONE}"
		whiptail --backtitle "${apptitle}" --title "${txttimezone}" --msgbox "${msg}" 8 0
		set_option "TIMEZONE" "${TIMEZONE}"
		mainmenu "${txtlocale}"
	fi
}

# ----------------------------------------------------------------------------------------------------

set_locale() {
	locales=$(ls /usr/share/i18n/locales)
	options=()
	for loc in ${locales}; do
		if [[ ${loc} == "en_US" ]]; then
			options+=("${loc}" "locale" on)
		else
			options+=("${loc}" "locale" off)
		fi
	done

	if locale=$(whiptail --backtitle "${apptitle}" --title "${txtlocale}" \
		--checklist "${txtselectlocales}" 30 45 22 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		set_option "LOCALES" "(${locale})"
	else
		msg="No locale selected.\nDefault: en_US"
		whiptail --backtitle "${apptitle}" --title "${txtlocale}" --msgbox "${msg}" 8 0
		set_option "LOCALES" "(en_US)"
		mainmenu "${txtkeymap}"
	fi
}

# ----------------------------------------------------------------------------------------------------

set_keymap() {
	keymaps=$(localectl list-keymaps)
	options=()
	for item in ${keymaps}; do
		options+=("${item}" "")
	done
	#keymaps=$(find /usr/share/kbd/keymaps/ -type f -printf "%f\n" | sort -V)
	#options=()
	#for item in ${keymaps}; do
	#	options+=("${item%%.*}" "")
	#done

	if keymap=$(whiptail --backtitle "${apptitle}" --title "${txtkeymap}" \
		--menu "${txtselectkeyboard}" 30 45 22 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		set_option "KEYMAP" "${keymap}"
	else
		msg="No keymap selected.\nDefault: us"
		whiptail --backtitle "${apptitle}" --title "${txtkeymap}" --msgbox "${msg}" 8 0
		set_option "KEYMAP" "us"
		mainmenu "${txtconsolefont}"
	fi
}

# ----------------------------------------------------------------------------------------------------

set_consolefont() {
	fonts=$(find /usr/share/kbd/consolefonts/ -name "*.psfu.gz" -o -name "*.psf.gz" -printf "%f\n")
	options=()
	for item in ${fonts}; do
		options+=("${item%%.*}" "")
	done

	if vcfont=$(whiptail --backtitle "${apptitle}" --title "${txtconsolefont}" \
		--menu "${txtselectvcfont}" 30 45 22 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		set_option "CONSOLEFONT" "${vcfont}"
	else
		msg="No font selected.\nDefault: ter-v20b"
		whiptail --backtitle "${apptitle}" --title "${txtconsolefont}" --msgbox "${msg}" 8 0
		set_option "CONSOLEFONT" "ter-v20b"
		mainmenu "${txtdiskpartmenu}"
	fi
}

# ----------------------------------------------------------------------------------------------------

boot_mode() {
	if [[ ! -d "/sys/firmware/efi" ]]; then
		whiptail --backtitle "${apptitle}" --title "${txtbootmode}" \
			--msgbox "${txtbootmodemsg//%1/BIOS}" 7 38

		BOOT_MODE="bios"
		set_option "BOOT_MODE" "bios"
	else
		whiptail --backtitle "${apptitle}" --title "${txtbootmode}" \
			--msgbox "${txtbootmodemsg//%1/UEFI}" 7 38

		BOOT_MODE="uefi"
		set_option "BOOT_MODE" "uefi"
	fi
}

diskpartmenu() {
	if [[ ${1} == "" ]]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txtselectdisk}" "")
	options+=("${txtpartitiontable}" "")
	options+=("${txtformatpartitions}" "")
	options+=("${txtswapfile}" "")
	options+=("" "")
	options+=("${txtmainmenu}" "")

	if diskmenupick=$(whiptail --backtitle "${apptitle}" --title "${txtdiskpartmenu}" \
		--cancel-button "${txtback}" --default-item "${nextitem}" \
		--menu "Prepare the installation disk:" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		case ${diskmenupick} in
		"${txtselectdisk}")
			select_disk
			nextitem="${txtpartitiontable}"
			;;
		"${txtpartitiontable}")
			partition_table
			nextitem="${txtformatpartitions}"
			;;
		"${txtformatpartitions}")
			format_partitions
			nextitem="${txtswapfile}"
			;;
		"${txtswapfile}")
			swapfile
			nextitem="${txtmainmenu}"
			;;
		"${txtmainmenu}")
			mainmenu "${txtusersmenu}"
			nextitem="${txtusersmenu}"
			;;
		*) ;;
		esac
		diskpartmenu "${nextitem}"
	else
		mainmenu "${txtdiskpartmenu}"
	fi
}

select_disk() {
	disks=$(lsblk -d -p -n -l -o NAME,SIZE -e 7,11)
	options=()
	IFS_ORIG=${IFS}
	IFS=$'\n'
	for disk in ${disks}; do
		options+=("${disk}" "")
	done
	IFS=${IFS_ORIG}
	if result=$(whiptail --backtitle "${apptitle}" --title "${txtdiskdevice}" \
		--menu "${txtaskdiskselection}" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		DISK="${result%%\ *}"
		if confirm_data_wipe; then
			set_option "DISK" "${DISK}"
		else
			diskpartmenu "${txtselectdisk}"
		fi
	else
		diskpartmenu "${txtselectdisk}"
	fi

	if (whiptail --backtitle "${apptitle}" --title "${txtdiskdevice}" \
		--defaultno --yesno "${txtaskdiskssd//%1/${DISK}}" 8 45); then

		set_option "SSD" "true"
		set_option "BTRFS_MOUNT_OPTIONS" "defaults,noatime,compress=zstd,ssd,commit=120"
	else
		set_option "SSD" "false"
		set_option "BTRFS_MOUNT_OPTIONS" "defaults,noatime,compress=zstd,commit=120"
	fi

	return 0
}

confirm_data_wipe() {
	if (whiptail --backtitle "${apptitle}" --title "${txtwarning}" \
		--defaultno --yesno "${txtconfirmwipedata//%1/${DISK}}" 8 45); then

		return 0
	else
		return 1
	fi
}

check_disk_selection() {
	if [[ -n ${DISK} ]]; then
		return 0
	else
		return 1
	fi
}

confirm_selected_disk() {
	if check_disk_selection; then
		if (whiptail --backtitle "${apptitle}" --title "${txtconfirm}" \
			--defaultno --yesno "${txtconfirmselecteddevice//%1/${DISK}}" 8 45); then

			return 0
		else
			DISK=""
			select_disk
			partition_table "${nextitem}"
		fi
	else
		msg="No device selected.\nSelect your disk first."
		whiptail --backtitle "${apptitle}" --title "${txterror}" --msgbox "${msg}" 8 0
		select_disk
		partition_table "${nextitem}"
	fi
}

delete_part_entries() {
	del_option "partition"
	del_option "SWAP_PARTITION"
	del_option "mountpoint"
	del_option "filesystem"
	del_option "btrfs_subvolumes"
	del_option "fs_pkgs"
	fs_pkgs=""
}

new_partition_table_mbr_or_gpt() {
	if [[ ! -d "/sys/firmware/efi" ]]; then
		message="The system is booted in BIOS mode."
		message+="\nDo you want to create a GPT or MBR partition table?"
		if (whiptail --backtitle "${apptitle}" --title "${txtpartitiontable}" \
			--yesno "${message}" 0 55 \
			--yes-button "GPT" \
			--no-button "MBR"); then

			PARTITION_TABLE="bios_gpt"
			set_option "PARTITION_TABLE" "bios_gpt"
		else
			PARTITION_TABLE="bios_mbr"
			set_option "PARTITION_TABLE" "bios_mbr"
		fi
	else
		PARTITION_TABLE="uefi_gpt"
		set_option "PARTITION_TABLE" "uefi_gpt"
		fs_pkgs="dosfstools"
	fi
}

partition_table() {
	if [[ ${1} == "" ]]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txtautoparts}" "")
	options+=("${txtmanualparts}" "")

	if disk_slicing=$(whiptail --backtitle "${apptitle}" --title "${txtpartitiontable}" \
		--cancel-button "${txtback}" --default-item "${nextitem}" \
		--menu "${txtselectpartitionscheme}" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		case ${disk_slicing} in
		"${txtautoparts}")
			autopartitiontable
			nextitem="${txtformatpartitions}"
			;;
		"${txtmanualparts}")
			manualpartitiontable
			nextitem="${txtformatpartitions}"
			;;
		*) ;;
		esac
		diskpartmenu "${nextitem}"
	else
		msg="${txtwarning} No partition scheme selected.\nDefault: %1_gpt / auto_partitions_noswap"
		if [[ ${BOOT_MODE} == "bios" ]]; then
			whiptail --backtitle "${apptitle}" --title "${txtpartitiontable}" --msgbox "${msg//%1/bios}" 8 47
			PARTITION_TABLE="bios_gpt"
			PARTITION_SCHEME="auto_partitions_noswap"
			set_option "PARTITION_TABLE" "bios_gpt"
			set_option "PARTITION_SCHEME" "auto_partitions_noswap"
			set_option "SWAP_PARTITION" "false"
		elif [[ ${BOOT_MODE} == "uefi" ]]; then
			whiptail --backtitle "${apptitle}" --title "${txtpartitiontable}" --msgbox "${msg//%1/uefi}" 8 47
			PARTITION_TABLE="uefi_gpt"
			PARTITION_SCHEME="auto_partitions_noswap"
			set_option "PARTITION_TABLE" "uefi_gpt"
			set_option "PARTITION_SCHEME" "auto_partitions_noswap"
			set_option "SWAP_PARTITION" "false"
			fs_pkgs="dosfstools"
		fi
		diskpartmenu "${txtformatpartitions}"
	fi
}

autopartitiontable() {
	new_partition_table_mbr_or_gpt
	options=()
	options+=("${txtautoparts} (With Swap)" "")
	options+=("${txtautoparts} (No Swap)" "")

	if auto_disk_slicing=$(whiptail --backtitle "${apptitle}" --title "${txtpartitiontable}" \
		--cancel-button "${txtback}" --menu "${txtselectpartitionscheme}" 10 0 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		case ${auto_disk_slicing} in
		"${txtautoparts} (With Swap)")
			nextitem="${txtautoparts}"
			delete_part_entries
			confirm_selected_disk
			PARTITION_SCHEME="auto_partitions_with_swap"
			set_option "PARTITION_SCHEME" "auto_partitions_with_swap"
			set_option "SWAP_PARTITION" "true"
			set_swap_size
			nextitem="${txtformatpartitions}"
			;;
		"${txtautoparts} (No Swap)")
			nextitem="${txtautoparts}"
			delete_part_entries
			confirm_selected_disk
			PARTITION_SCHEME="auto_partitions_noswap"
			set_option "PARTITION_SCHEME" "auto_partitions_noswap"
			set_option "SWAP_PARTITION" "false"
			nextitem="${txtformatpartitions}"
			;;
		*) ;;
		esac
		diskpartmenu "${nextitem}"
	else
		partition_table "${txtautoparts}"
	fi
}

set_swap_size() {
	ram=$(free -m -t | awk 'NR == 2 {print $2}')
	result=$((ram < 4096 ? ram : 4096))
	result=$((result + ((ram - 4096 > 0 ? ram - 4096 : 0) / 2)))
	result=$((result < 32 * 1024 ? result : 32 * 1024))

	swap_size=$(whiptail --backtitle "${apptitle}" --title "${txtswap}" \
		--inputbox "${txtaskswapsize}\n(Default = ${result} MiB)" 0 0 "${result}" 3>&1 1>&2 2>&3)

	SWAP_SIZE="${swap_size:=${result}}"
	set_option "SWAP_SIZE" "${SWAP_SIZE}"
}

manualpartitiontable() {
	options=()
	options+=("${txtmanualparts} (cfdisk)" "")
	options+=("${txtmanualparts} (cgdisk)" "")

	if manual_disk_slicing=$(whiptail --backtitle "${apptitle}" --title "${txtpartitiontable}" \
		--cancel-button "${txtback}" --menu "${txtselectpartitionscheme}" 10 41 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		case ${manual_disk_slicing} in
		"${txtmanualparts} (cfdisk)")
			nextitem="${txtmanualparts}"
			delete_part_entries
			confirm_selected_disk
			delete_partition_table
			cfdisk "${DISK}"
			if [[ ${BOOT_MODE} == "bios" ]]; then
				if [[ "$(fdisk -l "${DISK}" | grep "Disklabel type")" =~ "dos" ]]; then
					PARTITION_TABLE="bios_mbr"
					PARTITION_SCHEME="manual_partitions"
					set_option "PARTITION_TABLE" "bios_mbr"
					set_option "PARTITION_SCHEME" "manual_partitions"
				elif [[ "$(fdisk -l "${DISK}" | grep "Disklabel type")" =~ "gpt" ]]; then
					PARTITION_TABLE="bios_gpt"
					PARTITION_SCHEME="manual_partitions"
					set_option "PARTITION_TABLE" "bios_gpt"
					set_option "PARTITION_SCHEME" "manual_partitions"
				fi
			elif [[ ${BOOT_MODE} == "uefi" ]]; then
				PARTITION_TABLE="uefi_gpt"
				PARTITION_SCHEME="manual_partitions"
				set_option "PARTITION_TABLE" "uefi_gpt"
				set_option "PARTITION_SCHEME" "manual_partitions"
				fs_pkgs="dosfstools"
			fi
			nextitem="${txtformatpartitions}"
			;;
		"${txtmanualparts} (cgdisk)")
			nextitem="${txtmanualparts}"
			delete_part_entries
			confirm_selected_disk
			delete_partition_table
			cgdisk "${DISK}"
			if [[ ${BOOT_MODE} == "bios" ]]; then
				PARTITION_TABLE="bios_gpt"
				PARTITION_SCHEME="manual_partitions"
				set_option "PARTITION_TABLE" "bios_gpt"
				set_option "PARTITION_SCHEME" "manual_partitions"
			elif [[ ${BOOT_MODE} == "uefi" ]]; then
				PARTITION_TABLE="uefi_gpt"
				PARTITION_SCHEME="manual_partitions"
				set_option "PARTITION_TABLE" "uefi_gpt"
				set_option "PARTITION_SCHEME" "manual_partitions"
				fs_pkgs="dosfstools"
			fi
			nextitem="${txtformatpartitions}"
			;;
		*) ;;
		esac
		diskpartmenu "${nextitem}"
	else
		partition_table "${txtmanualparts}"
	fi
}

delete_partition_table() {
	if (whiptail --backtitle "${apptitle}" --title "${txtconfirm}" \
		--defaultno --yesno "${txtdeletepartitiontable}" 8 45); then
		wipefs -a -f "${DISK}" &>/dev/null
		return 0
	else
		return 1
	fi
}

check_partition_table_selection() {
	if [[ -n ${PARTITION_TABLE} ]]; then
		return 0
	else
		return 1
	fi
}

check_selected_disk_status() {
	disk_status="\n* Selected disk: ${DISK}\n\n"
	disk_status="${disk_status}* Partition table: ${PARTITION_TABLE}\n\n"
	if [[ ${PARTITION_TABLE} == bios_mbr && ${PARTITION_SCHEME} == auto_partitions_noswap ]]; then
		partition_layout="1- root partition"
		disk_status="${disk_status}* Partitioning layout:\n"
		disk_status="${disk_status}    ${partition_layout}\n\n"
	elif [[ ${PARTITION_TABLE} == bios_mbr && ${PARTITION_SCHEME} == auto_partitions_with_swap ]]; then
		partition_layout="1- swap partition\n    2- root partition"
		disk_status="${disk_status}* Partitioning layout:\n"
		disk_status="${disk_status}    ${partition_layout}\n\n"
	elif [[ ${PARTITION_TABLE} == bios_gpt && ${PARTITION_SCHEME} == auto_partitions_noswap ]]; then
		partition_layout="1- BIOS boot partition\n    2- root partition"
		disk_status="${disk_status}* Partitioning layout:\n"
		disk_status="${disk_status}    ${partition_layout}\n\n"
	elif [[ ${PARTITION_TABLE} == bios_gpt && ${PARTITION_SCHEME} == auto_partitions_with_swap ]]; then
		partition_layout="1- BIOS boot partition\n    2- swap partition\n    3- root partition"
		disk_status="${disk_status}* Partitioning layout:\n"
		disk_status="${disk_status}    ${partition_layout}\n\n"
	elif [[ ${PARTITION_TABLE} == uefi_gpt && ${PARTITION_SCHEME} == auto_partitions_noswap ]]; then
		partition_layout="1- EFI System partition\n    2- root partition"
		disk_status="${disk_status}* Partitioning layout:\n"
		disk_status="${disk_status}    ${partition_layout}\n\n"
	elif [[ ${PARTITION_TABLE} == uefi_gpt && ${PARTITION_SCHEME} == auto_partitions_with_swap ]]; then
		partition_layout="1- EFI System partition\n    2- swap partition\n    3- root partition"
		disk_status="${disk_status}* Partitioning layout:\n"
		disk_status="${disk_status}    ${partition_layout}\n\n"
	elif [[ ${PARTITION_SCHEME} == manual_partitions ]]; then
		disk_status="${disk_status}* Partitioning layout: ${PARTITION_SCHEME}\n\n"
		status_msg=$(fdisk -l "${DISK}")
		whiptail --backtitle "${apptitle}" --title "${txtselecteddiskstatus}" --msgbox "${status_msg}" 0 0
	fi
}
confirm_format_partitions() {
	if check_disk_selection; then
		if check_partition_table_selection; then
			check_selected_disk_status
			if (whiptail --backtitle "${apptitle}" --title "${txtselecteddiskstatus}" \
				--yesno "${disk_status}${txtconfirmformatpartitions}\n\n" 0 0); then

				return 0
			else
				return 1
			fi
		fi
	else
		msg="No device selected.\nSelect your disk and the partition scheme first."
		whiptail --backtitle "${apptitle}" --title "${txterror}" --msgbox "${msg}" 8 52
		select_disk
		partition_table
		format_partitions
	fi
}

format_partitions() {
	if confirm_format_partitions; then
		case ${PARTITION_SCHEME} in
		"auto_partitions_noswap" | "auto_partitions_with_swap") format_auto_partitions ;;
		"manual_partitions") format_manual_partitions ;;
		*) ;;
		esac
	else
		diskpartmenu "${txtformatpartitions}"
	fi
}

format_auto_partitions() {
	filesystem
	filesystem_pkgs
}

filesystem() {
	options=()
	options+=("ext4" "")
	options+=("btrfs" "")

	if filesystem=$(whiptail --backtitle "${apptitle}" --title "${txtfilesystem}" \
		--nocancel --menu "${txtselectfilesystem//%1/root}" 0 40 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		set_option "root_filesystem" "${filesystem}"

		case ${filesystem} in
		"btrfs")
			if [[ ! ${fs_pkgs} =~ "btrfs-progs" ]]; then
				fs_pkgs="${fs_pkgs} btrfs-progs"
			fi
			prompt_for_subvolumes_mountpoints
			;;
		"ext4")
			if [[ ! ${fs_pkgs} =~ "e2fsprogs" ]]; then
				fs_pkgs="${fs_pkgs} e2fsprogs"
			fi
			;;
		*) ;;
		esac

	else
		msg="\n${txtwarning} No filesystem selected.\nDefault: btrfs"
		whiptail --backtitle "${apptitle}" --title "${txtfilesystem}" --msgbox "${msg}" 8 0
		set_option "root_filesystem" "btrfs"
		set_option "btrfs_subvolumes" '("@" "@home" "@snapshots" "@swap" "@tmp" "@var_log")'
		set_option "btrfs_subvolumes_mountpoints" '("/" "/home" "/.snapshots" "/swap" "/tmp" "/var/log")'
		if [[ ! ${fs_pkgs} =~ "btrfs-progs" ]]; then
			fs_pkgs="${fs_pkgs} btrfs-progs"
		fi
	fi
}

filesystem_pkgs() {
	options=()
	if [[ ${fs_pkgs} == *"btrfs-progs"* ]]; then
		options+=("btrfs-progs" "" on)
	else
		options+=("btrfs-progs" "" off)
	fi

	if [[ ${fs_pkgs} == *"dosfstools"* ]]; then
		options+=("dosfstools" "" on)
	else
		options+=("dosfstools" "" off)
	fi

	if [[ ${fs_pkgs} == *"e2fsprogs"* ]]; then
		options+=("e2fsprogs" "" on)
	else
		options+=("e2fsprogs" "" off)
	fi

	if [[ ${fs_pkgs} == *"xfatprogs"* ]]; then
		options+=("xfatprogs" "" on)
	else
		options+=("xfatprogs" "" off)
	fi

	if [[ ${fs_pkgs} == *"xfsprogs"* ]]; then
		options+=("xfsprogs" "" on)
	else
		options+=("xfsprogs" "" off)
	fi

	if [[ ${fs_pkgs} == *"nilfs-utils"* ]]; then
		options+=("nilfs-utils" "" on)
	else
		options+=("nilfs-utils" "" off)
	fi

	if [[ ${fs_pkgs} == *"ntfs-3g"* ]]; then
		options+=("ntfs-3g" "" on)
	else
		options+=("ntfs-3g" "" off)
	fi

	if [[ ${fs_pkgs} == *"f2fs-tools"* ]]; then
		options+=("f2fs-tools" "" on)
	else
		options+=("f2fs-tools" "" off)
	fi

	if [[ ${fs_pkgs} == *"jfsutils"* ]]; then
		options+=("jfsutils" "" on)
	else
		options+=("jfsutils" "" off)
	fi

	if [[ ${fs_pkgs} == *"reiserfsprogs"* ]]; then
		options+=("reiserfsprogs" "" on)
	else
		options+=("reiserfsprogs" "" off)
	fi

	options+=("lvm2" "" off)
	options+=("dmraid" "" off)

	if sel=$(whiptail --backtitle "${apptitle}" --title "${txtfilesystem}" \
		--checklist "${txtfilesystempkgs}" 0 40 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		# Declare an array to store unique values
		declare -a unique_values=()

		for itm in ${sel}; do
			processed_value=${itm//\"/}

			# Check if the processed value is already in the unique_values array
			if [[ ! ${unique_values[*]} =~ ${processed_value} ]]; then
				unique_values+=("${processed_value}")
			fi
		done
		set_option "fs_pkgs" "(${unique_values[*]})"
	else
		msg="No additional filesystem packages selected."
		whiptail --backtitle "${apptitle}" --title "${txtfilesystem}" --msgbox "${msg}" 7 48
		return 1
	fi
}

format_manual_partitions() {

	options=()
	partitions=()
	partitions_types=()
	mountpoints=()
	filesystems=()

	# Retrieve the partition names for the specified disk
	partition_names=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}')

	index=1
	for p in ${partition_names}; do
		partitions+=("${p}")
		options+=("${index}) ${p}\n" "")
		index=$((index + 1))
	done
	set_option "partitions" "(${partitions[*]})"
	msg=$(printf "%s" "${options[@]}")
	msg="${msg}\nDo you want to continue?"

	if (whiptail --backtitle "${apptitle}" --title "${txtpartitionslist}" --yesno "${msg}" 0 0); then

		# Determine the number of partitions
		partitions_count=$(echo "${partition_names}" | wc -l)
		set_option "partitions_count" "${partitions_count}"

		# Assign each partition to a variable and prompt for mount point and filesystem
		for ((i = 0; i < ${#partitions[@]}; i++)); do

			options=()
			options+=("${partitions[i]}" "")
			if (whiptail --backtitle "${apptitle}" --title "Select Partition $((i + 1)):" \
				--nocancel --menu "" 0 40 0 "${options[@]}" 3>&1 1>&2 2>&3); then

				# Prompt for partition type using whiptail
				partition_type_prompt="What partition is ${partitions[i]} ?"
				options=()
				if [[ "$(fdisk -l "${DISK}" | grep "Disklabel type")" =~ "gpt" ]]; then
					options+=("bios_boot" "")
				fi
				if [[ ${BOOT_MODE} == "uefi" ]]; then
					options+=("efi" "")
				fi
				options+=("boot" "")
				options+=("root" "")
				options+=("home" "")
				options+=("swap" "")
				options+=("other" "")

				if partition_type=$(whiptail --backtitle "${apptitle}" --title "${txtpartitioninglayout}" \
					--nocancel --menu "${partition_type_prompt}" 0 40 0 "${options[@]}" 3>&1 1>&2 2>&3); then

					partitions_types+=("${partition_type}")
					set_option "partitions_types" "(${partitions_types[*]})"
					if [[ ${partition_type} != "other" ]]; then
						set_option "${partition_type}_partition" "${partitions[i]}"
					fi
				else
					diskpartmenu "${nextitem}"
				fi

				# Prompt for mount point using whiptail
				mountpoint_prompt="Select the mount point for ${partitions[i]}:"
				mountpoint_input="Enter the mount point for ${partitions[i]}:"
				options=()
				if [[ ${partition_type} == "bios_boot" ]]; then
					options+=("none" "(bios_boot)")
				elif [[ ${partition_type} == "efi" ]]; then
					options+=("/boot/efi" "")
					options+=("/boot" "")
				elif [[ ${partition_type} == "boot" ]]; then
					options+=("/boot" "")
				elif [[ ${partition_type} == "root" ]]; then
					options+=("/" "")
				elif [[ ${partition_type} == "home" ]]; then
					options+=("/home" "")
				elif [[ ${partition_type} == "swap" ]]; then
					options+=("none" "")
				else
					options+=("none" "")
					options+=("Enter manually" "")
				fi

				if select_mountpoint=$(whiptail --backtitle "${apptitle}" --title "${txtmountpoint}" \
					--nocancel --menu "${mountpoint_prompt}" 0 40 0 "${options[@]}" 3>&1 1>&2 2>&3); then

					if [[ ${select_mountpoint} == "Enter manually" ]]; then
						mountpoint=$(whiptail --backtitle "${apptitle}" --title "${txtmountpoint}" \
							--inputbox "${mountpoint_input}" 0 0 3>&1 1>&2 2>&3)
					else
						mountpoint="${select_mountpoint}"
					fi
					mountpoints+=("${mountpoint}")
					set_option "mountpoints" "(${mountpoints[*]})"
				else
					diskpartmenu "${nextitem}"
				fi

				# Prompt for filesystem using whiptail
				fs_prompt="Select the appropriate filesystem for ${partitions[i]}:"
				options=()
				if [[ ${partition_type} == "bios_boot" ]]; then
					options+=("none" "")
				elif [[ ${partition_type} == "boot" ]]; then
					options+=("ext4" "")
					options+=("fat32" "")
				elif [[ ${partition_type} == "efi" ]]; then
					options+=("fat32" "")
				elif [[ ${partition_type} == "swap" ]]; then
					options+=("swap" "")
				elif [[ ${partition_type} == "root" || ${partition_type} == "home" ]]; then
					options+=("ext4" "")
					options+=("btrfs" "")
				else
					options+=("ext4" "")
					options+=("btrfs" "")
					options+=("none" "")
				fi

				if filesystem=$(whiptail --backtitle "${apptitle}" --title "${txtfilesystem}" \
					--nocancel --menu "${fs_prompt}" 0 40 0 "${options[@]}" 3>&1 1>&2 2>&3); then

					case ${filesystem} in
					"btrfs")
						if [[ ${partition_type} == "root" ]]; then
							set_option "root_filesystem" "${filesystem}"
							prompt_for_subvolumes_mountpoints
						fi
						if [[ ! ${fs_pkgs} =~ "btrfs-progs" ]]; then
							fs_pkgs="${fs_pkgs} btrfs-progs"
						fi
						;;
					"ext4")
						if [[ ${partition_type} == "root" ]]; then
							set_option "root_filesystem" "${filesystem}"
						fi
						if [[ ! ${fs_pkgs} =~ "e2fsprogs" ]]; then
							fs_pkgs="${fs_pkgs} e2fsprogs"
						fi
						;;
					"fat32")
						if [[ ! ${fs_pkgs} =~ "dosfstools" ]]; then
							fs_pkgs="${fs_pkgs} dosfstools"
						fi
						;;
					*) ;;
					esac
					filesystems+=("${filesystem}")
					set_option "filesystems" "(${filesystems[*]})"
				else
					diskpartmenu "${nextitem}"
				fi
			else
				diskpartmenu "${nextitem}"
			fi
		done
		filesystem_pkgs
	else
		diskpartmenu "${nextitem}"
	fi
}

# Function to prompt for subvolumes and mountpoints
prompt_for_subvolumes_mountpoints() {
	local btrfs_subvolumes=()
	local btrfs_subvolumes_mountpoints=()

	while true; do
		subvolume=$(whiptail --backtitle "${apptitle}" --title "${txtbtrfssubvolumes}" \
			--nocancel --inputbox "${txtentersubvolnames}" 9 45 3>&1 1>&2 2>&3)
		if [[ -z ${subvolume} ]]; then
			break
		fi

		mountpoint=$(whiptail --backtitle "${apptitle}" --title "${txtbtrfssubvolumes}" \
			--nocancel --inputbox "${txtentersubvolmntpts} '${subvolume}':" 9 45 3>&1 1>&2 2>&3)
		if [[ -z ${mountpoint} ]]; then
			break
		fi

		btrfs_subvolumes+=("${subvolume}")
		btrfs_subvolumes_mountpoints+=("${mountpoint}")
	done

	if [[ ${#btrfs_subvolumes[@]} -eq 0 ]] || [[ ${#btrfs_subvolumes_mountpoints[@]} -eq 0 ]]; then
		msg="Default btrfs filesystem layout set:\n- @\n- @home\n- @snapshots\n- @swap\n- @tmp\n- @var_log"
		whiptail --backtitle "${apptitle}" --title "${txtbtrfssubvolumes}" --msgbox "${msg}" 0 0
		set_option "btrfs_subvolumes" '("@" "@home" "@snapshots" "@swap" "@tmp" "@var_log")'
		set_option "btrfs_subvolumes_mountpoints" '("/" "/home" "/.snapshots" "/swap" "/tmp" "/var/log")'
	else
		set_option "btrfs_subvolumes" "(${btrfs_subvolumes[*]})"
		set_option "btrfs_subvolumes_mountpoints" "(${btrfs_subvolumes_mountpoints[*]})"
	fi
}

swapfile() {
	if (whiptail --backtitle "${apptitle}" --title "${txtswapfile}" \
		--defaultno --yesno "${txtaskswapfile}" 7 38); then

		set_option "SWAPFILE" "true"

		ram=$(free -m -t | awk 'NR == 2 {print $2}')
		result=$((ram < 4096 ? ram : 4096))
		result=$((result + ((ram - 4096 > 0 ? ram - 4096 : 0) / 2)))
		result=$((result < 32 * 1024 ? result : 32 * 1024))

		swapfile_size=$(whiptail --backtitle "${apptitle}" --title "${txtswapfile}" \
			--inputbox "${txtswapfilesize}\n(Default = ${result} MiB)" 0 0 "${result}" 3>&1 1>&2 2>&3)

		SWAPFILE_SIZE="${swapfile_size:=${result}}"
		set_option "SWAPFILE_SIZE" "${SWAPFILE_SIZE}"

	else
		set_option "SWAPFILE" "false"
	fi
}

# ----------------------------------------------------------------------------------------------------

usersmenu() {
	if [[ ${1} == "" ]]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txtsethostname}" "")
	options+=("${txtsetusername}" "")
	options+=("${txtsetpassword//%1/Root}" "")
	options+=("${txtsetpassword//%1/User}" "")
	options+=("" "")
	options+=("${txtmainmenu}" "")

	if usersmenupick=$(whiptail --backtitle "${apptitle}" --title "${txtusersmenu}" \
		--cancel-button "${txtback}" --default-item "${nextitem}" \
		--menu "Set up users and passwords:" 0 45 0 "${options[@]}" 3>&1 1>&2 2>&3); then

		case ${usersmenupick} in
		"${txtsethostname}")
			set_hostname
			nextitem="${txtsetusername}"
			;;
		"${txtsetusername}")
			set_username
			nextitem="${txtsetpassword//%1/Root}"
			;;
		"${txtsetpassword//%1/Root}")
			set_rootpassword
			nextitem="${txtsetpassword//%1/User}"
			;;
		"${txtsetpassword//%1/User}")
			set_userpassword
			nextitem="${txtmainmenu}"
			;;
		"${txtmainmenu}")
			mainmenu "${txtinstallmenu}"
			nextitem="${txtinstallmenu}"
			;;
		*) ;;
		esac
		usersmenu "${nextitem}"
	else
		mainmenu "${txtusersmenu}"
	fi
}

set_hostname() {
	hostname=$(whiptail --backtitle "${apptitle}" --title "${txtsethostname}" \
		--nocancel --inputbox "Enter the hostname for this system:" 8 45 "ArchLinux" 3>&1 1>&2 2>&3)

	if [[ $? != "0" ]] || [[ -z ${hostname} ]]; then
		msg="No hostname set.\nTry again."
		whiptail --backtitle "${apptitle}" --title "${txterror}" --msgbox "${msg}" 8 0
		set_hostname
	else
		set_option "HOSTNAME" "${hostname}"

	fi
}

set_username() {
	username=$(whiptail --backtitle "${apptitle}" --title "${txtsetusername}" \
		--nocancel --inputbox "Username for your account:" 8 45 "" 3>&1 1>&2 2>&3)

	if [[ $? != "0" ]] || [[ -z ${username} ]]; then
		msg="No username set.\nTry again."
		whiptail --backtitle "${apptitle}" --title "${txterror}" --msgbox "${msg}" 8 0
		set_username
	else
		set_option "USERNAME" "${username}"
	fi
}

set_password() {
	PASSWORD1=$(whiptail --backtitle "${apptitle}" --title "${txtpassword//%1/${1}}" \
		--nocancel --passwordbox "${txtaskpassword//%1/Enter}" 8 45 3>&1 1>&2 2>&3)

	PASSWORD2=$(whiptail --backtitle "${apptitle}" --title "${txtpassword//%1/${1}}" \
		--nocancel --passwordbox "${txtaskpassword//%1/Confirm}" 8 45 3>&1 1>&2 2>&3)

	if [[ ${PASSWORD1} != "${PASSWORD2}" ]]; then
		msg="Passwords do not match.\nTry again."
		whiptail --backtitle "${apptitle}" --title "${txterror}" --msgbox "${msg}" 8 0
		set_password "$1" "$2"
	else
		if [[ -z ${PASSWORD1} ]]; then
			msg="No password set.\nTry again."
			whiptail --backtitle "${apptitle}" --title "${txterror}" --msgbox "${msg}" 8 0
			set_password "$1" "$2"
		else
			set_option "$2" "${PASSWORD1}"
		fi
	fi
}

set_rootpassword() {
	set_password "ROOT" "ROOT_PASSWORD"
}

set_userpassword() {
	set_password "USER" "USER_PASSWORD"
}

# ----------------------------------------------------------------------------------------------------

installmenu() {
	if [[ ${1} == "" ]]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txtkernel}" "")
	options+=("${txtdesktopenv}" "")
	options+=("${txtinstalltype}" "")
	options+=("${txtaurhelper}" "")
	options+=("${txtflatpak}" "")
	options+=("" "")
	options+=("${txtmainmenu}" "")
	if sel=$(whiptail --backtitle "${apptitle}" --title "${txtinstallmenu}" \
		--cancel-button "${txtback}" --default-item "${nextitem}" \
		--menu "Choose the desired installation settings:" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		case ${sel} in
		"${txtkernel}")
			install_kernel
			nextitem="${txtdesktopenv}"
			;;
		"${txtdesktopenv}")
			install_desktop_env
			nextitem="${txtinstalltype}"
			;;
		"${txtinstalltype}")
			install_type
			nextitem="${txtaurhelper}"
			;;
		"${txtaurhelper}")
			install_aur_helper
			nextitem="${txtflatpak}"
			;;
		"${txtflatpak}")
			install_flatpak
			nextitem="${txtmainmenu}"
			;;
		"${txtmainmenu}")
			mainmenu "${txtsummary}"
			nextitem="${txtsummary}"
			;;
		*) ;;
		esac
		installmenu "${nextitem}"
	else
		mainmenu "${txtinstallmenu}"
	fi
}

install_kernel() {
	options=()
	options+=("linux" "")
	options+=("linux-lts" "")
	options+=("linux-hardened" "")

	if kernel=$(whiptail --backtitle "${apptitle}" --title "${txtkernel}" \
		--menu "${txtselectkernel}" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		msg="Selected kernel: ${kernel}"
		case ${kernel} in
		"linux")
			whiptail --backtitle "${apptitle}" --title "${txtkernel}" --msgbox "${msg}" 7 0
			set_option "kernel_pkgs" '("linux" "linux-headers" "linux-docs")'
			;;
		"linux-lts")
			whiptail --backtitle "${apptitle}" --title "${txtkernel}" --msgbox "${msg}" 7 0
			set_option "kernel_pkgs" '("linux-lts" "linux-lts-headers" "linux-lts-docs")'
			;;
		"linux-hardened")
			whiptail --backtitle "${apptitle}" --title "${txtkernel}" --msgbox "${msg}" 7 0
			set_option "kernel_pkgs" '("linux-hardened" "linux-hardened-headers" "linux-hardened-docs")'
			;;
		*) ;;
		esac
	else
		msg="No kernel selected.\nDefault: linux"
		whiptail --backtitle "${apptitle}" --title "${txtkernel}" --msgbox "${msg}" 8 0
		set_option "kernel_pkgs" '("linux" "linux-headers" "linux-docs")'
	fi
}
install_desktop_env() {
	items=($(for f in pkg-files/*.txt; do echo "${f}" | sed -r "s/.+\/(.+)\..+/\1/;/pkgs/d"; done))
	options=()
	for item in "${items[@]}"; do
		options+=("${item}" "")
	done

	if desktop_env=$(whiptail --backtitle "${apptitle}" --title "${txtdesktopenv}" \
		--menu "${txtselectdesktopenv}" 0 45 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		msg="Desktop Environment to be installed:\n> ${desktop_env}"
		whiptail --backtitle "${apptitle}" --title "${txtdesktopenv}" --msgbox "${msg}" 8 0
		set_option "DESKTOP_ENV" "${desktop_env}"
	else
		msg="No Desktop Environment selected.\nDefault: kde"
		whiptail --backtitle "${apptitle}" --title "${txtdesktopenv}" --msgbox "${msg}" 8 0
		set_option "DESKTOP_ENV" "kde"
	fi
}

install_type() {
	options=()
	options+=("Minimal" "A minimal functional desktop with only few selected apps to get you started" on)
	options+=("Full" "A full featured desktop, with added apps and themes needed for everyday use" off)

	if install_type=$(whiptail --backtitle "${apptitle}" --title "${txtinstalltype}" \
		--radiolist "${txtselectinstalltype}" 0 0 0 \
		"${options[@]}" 3>&1 1>&2 2>&3); then

		msg="You selected: ${install_type} installation"
		whiptail --backtitle "${apptitle}" --title "${txtinstalltype}" --msgbox "${msg}" 7 0
		set_option "INSTALL_TYPE" "${install_type}"
	else
		msg="Nothing selected.\nDefault: Minimal"
		whiptail --backtitle "${apptitle}" --title "${txtinstalltype}" --msgbox "${msg}" 8 0
		set_option "INSTALL_TYPE" "Minimal"
	fi
}

install_aur_helper() {
	options=()
	options+=("yay" "")
	options+=("yay-bin" "")
	options+=("paru" "")
	options+=("paru-bin" "")
	options+=("aura" "")
	options+=("trizen" "")
	options+=("picaur" "")
	options+=("pacaur" "")
	options+=("none" "")

	if select_aur=$(whiptail --backtitle "${apptitle}" --title "${txtaurhelper}" \
		--menu "${txtselectaurhelper}" 0 45 0 "${options[@]}" 3>&1 1>&2 2>&3); then

		if [[ ${select_aur} != "none" ]]; then
			msg="AUR helper to be installed: ${select_aur}"
			whiptail --backtitle "${apptitle}" --title "${txtaurhelper}" --msgbox "${msg}" 7 0
			set_option "AUR_HELPER" "${select_aur}"
		else
			msg="No AUR helper to be installed."
			whiptail --backtitle "${apptitle}" --title "${txtaurhelper}" --msgbox "${msg}" 7 34
			set_option "AUR_HELPER" "none"
		fi
	else
		msg="No AUR helper to be installed."
		whiptail --backtitle "${apptitle}" --title "${txtaurhelper}" --msgbox "${msg}" 7 34
		set_option "AUR_HELPER" "none"
	fi
}

install_flatpak() {
	if (whiptail --backtitle "${apptitle}" --title "${txtflatpak}" \
		--yesno "${txtinstallflatpak}" 7 35); then

		set_option "FLATPAK" "true"
	else
		set_option "FLATPAK" "false"
	fi
}

# ----------------------------------------------------------------------------------------------------
summary() {
	# Define the path to the file you want to edit
	file_path="${CONFIG_FILE}"

	display_file
	edit_file
}

# Function to display the file content in a whiptail box
display_file() {
	whiptail --backtitle "${apptitle}" --title "${txtconfigfile}" --textbox "${file_path}" 35 90
}

# Function to edit the file
edit_file() {

	if whiptail --backtitle "${apptitle}" --title "${txtconfigfile}" \
		--yesno "Do you want to edit anything?" 7 33; then

		# Create a temporary file to hold the edited content
		temp_file=$(mktemp)

		# Copy the content of the original file to the temporary file
		cp "${file_path}" "${temp_file}"

		# Open a text editor
		"${EDITOR}" "${temp_file}"
		if
			# Prompt the user to save the changes
			whiptail --backtitle "${apptitle}" --title "${txtconfigfile}" \
				--yesno "Do you want to save the changes?" 7 36
		then
			# If the user chooses to save the changes, overwrite the original file
			cp "${temp_file}" "${file_path}"
			whiptail --backtitle "${apptitle}" --title "${txtconfigfile}" \
				--msgbox "Changes saved successfully!" 7 31
		else
			whiptail --backtitle "${apptitle}" --title "${txtconfigfile}" \
				--msgbox "Changes discarded." 7 22
		fi

		# Remove the temporary file
		rm "${temp_file}"
	fi
}

# ----------------------------------------------------------------------------------------------------

install_arch() {
	if (whiptail --backtitle "${apptitle}" --title "${txtinstallarch}" \
		--defaultno --yesno "Start Arch Linux installation?" 7 34); then

		clear
		return 0
	else
		return 1
	fi
}

# ----------------------------------------------------------------------------------------------------

background_checks
EDITOR=nano
load_strings
welcome
default_values
mainmenu

if [[ ${desktop_env,,} == server ]]; then
	set_option "INSTALL_TYPE" "Minimal"
	set_option "AUR_HELPER" "none"
	set_option "FLATPAK" "false"
fi

# ----------------------------------------------------------------------------------------------------

source "${PROJECT_DIR}/setup.conf"
(bash "${PROJECT_DIR}/scripts/1-pre-install.sh") |& tee 1-pre-install.log
(bash "${PROJECT_DIR}/scripts/2-arch-install.sh") |& tee 2-arch-install.log
(arch-chroot /mnt "${HOME}/aalis/scripts/3-setup.sh") |& tee 3-setup.log
if [[ ${DESKTOP_ENV,,} != "server" ]]; then
	(arch-chroot /mnt /usr/bin/runuser -u "${USERNAME}" -- bash "/home/${USERNAME}/aalis/scripts/4-user.sh") |& tee 4-user.log
	if [[ ${INSTALL_TYPE,,} == full ]]; then
		(arch-chroot /mnt /usr/bin/runuser -u "${USERNAME}" -- bash "/home/${USERNAME}/aalis/scripts/5-settings.sh") |& tee 5-settings.log
	fi
fi
(arch-chroot /mnt bash "${HOME}/aalis/scripts/6-post-install.sh") |& tee 6-post-install.log
cp -v ./*.log "/mnt/home/${USERNAME}/"

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
                 Done - Please eject install media and reboot
================================================================================
                  Type 'exit', 'umount -R /mnt' and 'reboot'
================================================================================
"
