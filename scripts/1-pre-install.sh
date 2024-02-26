#!/usr/bin/env bash
#
# @file Pre-Install
# @brief Contains the steps necessary to partition the disk, format the partitions and mount the file systems.

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
echo ":: sourcing '${PROJECT_DIR}/setup.conf'..."
source "${PROJECT_DIR}/setup.conf"

if [[ ${PARTITION_SCHEME} =~ auto_partitions ]]; then
	echo "
================================================================================
 Wiping DATA on disk
================================================================================
"
	# Make sure everything is unmounted before we start
	umount -A --recursive /mnt

	# Wipe the disk
	echo "[*] Wiping all data on ${DISK}..."
	wipefs -a -f "${DISK}"
	sgdisk -Z "${DISK}" # zap all on disk

	echo "
================================================================================
 Partitioning the disk
================================================================================
"
	create_mbr_partition_table() {
		echo "[*] Creating a new MBR partition table on ${DISK}..."
		echo 'label: dos' | sfdisk "${DISK}"
	}

	create_gpt_partition_table() {
		echo "[*] Creating a new GPT partition table on ${DISK}..."
		sgdisk -a 2048 -o "${DISK}"
	}

	reread_partition_table() {
		partprobe "${DISK}"
		sleep 3
	}

	auto_partitions_noswap() {
		if [[ ${PARTITION_TABLE} == bios_mbr ]]; then
			create_mbr_partition_table
			echo "[*] Creating the partitions..."
			echo 'type=83, bootable' | sfdisk "${DISK}"
			reread_partition_table
			root_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==1')

		elif [[ ${PARTITION_TABLE} == bios_gpt ]]; then
			create_gpt_partition_table
			echo "[*] Creating the partitions..."
			sgdisk --new=1::+1M --typecode=1:ef02 --change-name=1:"BIOS Boot" "${DISK}"
			sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:"ArchLinux Root" "${DISK}"
			reread_partition_table
			bios_boot_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==1')
			root_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==2')

		elif [[ ${PARTITION_TABLE} == uefi_gpt ]]; then
			create_gpt_partition_table
			echo "[*] Creating the partitions..."
			sgdisk --new=1::+1024M --typecode=1:ef00 --change-name=1:"EFI System Partition" "${DISK}"
			sgdisk --new=2::-0 --typecode=2:8300 --change-name=2:"ArchLinux Root" "${DISK}"
			reread_partition_table
			efi_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==1')
			root_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==2')
		fi
	}

	auto_partitions_with_swap() {
		if [[ ${PARTITION_TABLE} == bios_mbr ]]; then
			create_mbr_partition_table
			echo "[*] Creating the partitions..."
			printf 'size=+%sM, type=S\nsize=+, type=L, bootable\n' "${SWAP_SIZE}" | sfdisk "${DISK}"
			reread_partition_table
			swap_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==1')
			root_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==2')

		elif [[ ${PARTITION_TABLE} == bios_gpt ]]; then
			create_gpt_partition_table
			echo "[*] Creating the partitions..."
			sgdisk --new=1::+1M --typecode=1:ef02 --change-name=1:"BIOS Boot" "${DISK}"
			sgdisk --new=2::+"${SWAP_SIZE}"M --typecode=2:8200 --change-name=2:"Swap" "${DISK}"
			sgdisk --new=3::-0 --typecode=3:8300 --change-name=3:"ArchLinux Root" "${DISK}"
			reread_partition_table
			bios_boot_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==1')
			swap_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==2')
			root_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==3')

		elif [[ ${PARTITION_TABLE} == uefi_gpt ]]; then
			create_gpt_partition_table
			echo "[*] Creating the partitions..."
			sgdisk --new=1::+1024M --typecode=1:ef00 --change-name=1:"EFI System Partition" "${DISK}"
			sgdisk --new=2::+"${SWAP_SIZE}"M --typecode=2:8200 --change-name=2:"Swap" "${DISK}"
			sgdisk --new=3::-0 --typecode=3:8300 --change-name=3:"ArchLinux Root" "${DISK}"
			reread_partition_table
			efi_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==1')
			swap_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==2')
			root_partition=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}' | awk 'NR==3')
		fi
	}

	if [[ ${PARTITION_SCHEME} == auto_partitions_noswap ]]; then
		auto_partitions_noswap
	elif [[ ${PARTITION_SCHEME} == auto_partitions_with_swap ]]; then
		auto_partitions_with_swap
	fi
fi

echo "
================================================================================
 Formatting the partitions
================================================================================
"
format_auto_partitions() {
	partitions=$(fdisk -l "${DISK}" | grep "^${DISK}" | awk '{print $1}')
	for partition in ${partitions}; do
		case ${partition} in
		"${bios_boot_partition}")
			continue
			;;
		"${efi_partition}")
			echo "[*] Formatting the EFI system partition as fat32..."
			mkfs.fat -F 32 "${partition}"
			;;
		"${swap_partition}")
			echo "[*] Formatting the swap partition..."
			mkswap "${partition}"
			swapon "${partition}"
			;;
		"${root_partition}")
			echo "[*] Formatting the root partition as ${root_filesystem}..."
			if [[ ${root_filesystem} == btrfs ]]; then
				mkfs.btrfs -f "${partition}"
			elif [[ ${root_filesystem} == ext4 ]]; then
				mkfs.ext4 -F "${partition}"
			fi
			;;
		*) printf "\nBad disk format request.\nCan't make that disk format.\n" && exit 1 ;;
		esac
	done
}

format_manual_partitions() {
	for ((i = 0; i < partitions_count; i++)); do
		case ${filesystems[i]} in
		"none") continue ;;
		"fat32") mkfs.fat -F 32 "${partitions[i]}" ;;
		"ext4") mkfs.ext4 -F "${partitions[i]}" ;;
		"btrfs") mkfs.btrfs -f "${partitions[i]}" ;;
		"swap")
			mkswap "${partitions[i]}"
			swapon "${partitions[i]}"
			;;
		*) printf "\nBad disk format request.\nCan't make that disk format.\n" && exit 1 ;;
		esac
	done
}

if [[ ${PARTITION_SCHEME} =~ auto_partitions ]]; then
	format_auto_partitions
elif [[ ${PARTITION_SCHEME} == manual_partitions ]]; then
	format_manual_partitions
fi

echo "
================================================================================
 Mounting the file systems
================================================================================
"
create_subvolumes() {
	echo "[*] Creating btrfs subvolumes..."
	for ((i = 0; i < ${#btrfs_subvolumes[@]}; i++)); do
		btrfs subvolume create "/mnt/${btrfs_subvolumes[i]}"
	done
}

mount_subvolumes() {
	echo "[*] Mounting the subvolumes..."
	for ((i = 0; i < ${#btrfs_subvolumes[@]}; i++)); do

		mkdir -p "/mnt${btrfs_subvolumes_mountpoints[i]}"
		mount -o "${BTRFS_MOUNT_OPTIONS},subvol=${btrfs_subvolumes[i]}" "${root_partition}" "/mnt${btrfs_subvolumes_mountpoints[i]}"
	done
}

subvolumes_setup() {
	create_subvolumes
	umount /mnt
	mount_subvolumes
}

mount_auto_partitions() {
	if [[ ${root_filesystem} == btrfs ]]; then
		echo "[*] Mounting the root partition..."
		mount -t btrfs "${root_partition}" /mnt
		subvolumes_setup
	elif [[ ${root_filesystem} == ext4 ]]; then
		echo "[*] Mounting the root partition..."
		mount -t ext4 "${root_partition}" /mnt
	fi
	if [[ ${BOOT_MODE} == uefi ]]; then
		echo "[*] Mounting the EFI system partition..."
		mount --mkdir "${efi_partition}" /mnt/boot
	fi
}

mount_manual_partitions() {
	if [[ ${root_filesystem} == btrfs ]]; then
		echo "[*] Mounting the root partition..."
		mount -t btrfs "${root_partition}" /mnt
		subvolumes_setup
	elif [[ ${root_filesystem} == ext4 ]]; then
		echo "[*] Mounting the root partition..."
		mount -t ext4 "${root_partition}" /mnt
	fi

	echo "[*] Mounting non root partitions..."
	for ((i = 0; i < partitions_count; i++)); do
		case "${partitions[i]}" in
		"${bios_boot_partition}" | "${root_partition}" | "${swap_partition}")
			continue
			;;
		"${efi_partition}") mount --mkdir "${efi_partition}" "/mnt${mountpoints[i]}" ;;
		"${boot_partition}") mount --mkdir "${boot_partition}" /mnt/boot ;;
		"${home_partition}") mount --mkdir "${home_partition}" /mnt/home ;;
		*)
			if [[ ${mountpoints[i]} != none ]]; then
				mount --mkdir "${partitions[i]}" "/mnt${mountpoints[i]}"
			fi
			;;
		esac
	done
}

if [[ ${PARTITION_SCHEME} =~ auto_partitions ]]; then
	mount_auto_partitions
elif [[ ${PARTITION_SCHEME} == manual_partitions ]]; then
	mount_manual_partitions
fi

if ! grep -qs '/mnt' /proc/mounts; then
	echo "Drive is not mounted! Can not continue." && sleep 1
	echo "Rebooting in 3s..." && sleep 1
	echo "Rebooting in 2s..." && sleep 1
	echo "Rebooting in 1s..." && sleep 1
	reboot now
fi

echo "
================================================================================

                       SYSTEM READY FOR 2-arch-install.sh
                         
================================================================================
"
sleep 1
clear
exit 0
