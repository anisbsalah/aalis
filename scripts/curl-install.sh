#!/usr/bin/env bash

# Checking if running in repo folder
if [[ "$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]')" =~ ^scripts$ ]]; then
	echo "You are running this in 'aalis' folder."
	echo "Please use ./aalis.sh instead!"
	exit
fi

# Installing git
printf "\n[*] Installing 'git'...\n\n"
pacman -Sy --noconfirm --needed git

# Cloning project
printf "\n[*] Cloning 'aalis' project...\n\n"
git clone https://github.com/anisbsalah/aalis.git

# Executing script
printf "\n[*] Executing 'aalis.sh' script...\n\n"
cd "${HOME}/aalis" || exit 1
exec ./aalis.sh
