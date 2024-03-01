# AALIS: Automated Arch Linux Installation Script

This is an Arch Linux automated installation script. \
This script will guide you through the process of installing Arch Linux on your system. It provides a user-friendly menu using dialog boxes created with the dialog utility. This will allow you to easily navigate and select various settings and options to customize your Arch Linux installation. \
Simply follow the prompts and make your selections to proceed with the automated installation process.

Enjoy the power and flexibility of Arch Linux!

## Download Arch ISO

Download the Arch ISO from <https://archlinux.org/download/> and put it on a USB drive with [Etcher](https://www.balena.io/etcher/), [Rufus](https://rufus.ie/en/), or [Ventoy](https://www.ventoy.net/en/index.html).

## Boot Arch ISO

From the initial prompt, type the following commands after waiting a few seconds (as explained [here](#error-keyring-is-not-writable)):

```bash
pacman -Sy git
git clone https://github.com/anisbsalah/aalis
cd aalis
./aalis.sh
```

- Single command quicklaunch:

```bash
bash <(curl -L https://github.com/anisbsalah/aalis/raw/main/scripts/curl-install.sh)
```

## Troubleshooting

### **No WiFi**

You can check if WiFi is blocked by running `rfkill list`.
If it says **Soft blocked: yes**, then run `rfkill unblock wifi`

After unblocking the WiFi, you can connect to it. Go through these 5 steps:

1. Run `iwctl`

2. Run `device list`, and find your device name.

3. Run `station [device name] scan`

4. Run `station [device name] get-networks`

5. Find your network, and run `station [device name] connect [network name]`, enter your password and run `exit`. You can test if you have internet connection by running `ping archlinux.org`

Alternatively, you can connect using a single command line:

```bash
iwctl --passphrase "wifi_passphrase" station "device_name" connect "network_name"
```

### **error: keyring is not writable**

If you get this error when installing git:

```
downloading required keys...
error: keyring is not writable
error: required key missing from keyring
error: failed to commit transaction (unexpected error)
Errors occurred, no packages were upgraded.
```

Reboot the ISO and wait at least 15 seconds before installing git. \
When starting the Arch ISO, it will update the keyring and trust database in the background. \
You can run `journalctl -f` and wait until it says something like **next trustdb check due at 2022-05-6** and **Finished Initializes Pacman keyring**.

### **Script failing constantly**

If the script fails multiple times, try to remove `install.conf` and run the script again.

### **Timezone won't get detected**

Make sure the domains `ipapi.co` and `ifconfig.co` don't get blocked by your firewall.

## Credits

- The main menu script is inspired by [archfi](https://github.com/MatMoul/archfi).

- All the other scripts are scripts from the [ArchTitus](https://github.com/ChrisTitusTech/ArchTitus) project after some modifications.
