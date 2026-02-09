#!/bin/bash

set -euo pipefail

pacman_packages=("apparmor" "base-devel" "btrfs-assistant" "clang" "fastfetch" "gcc" "ghostty" "git" "go" "gradle" "jdk-openjdk" "jre-openjdk" "libreoffice-still" "linux-lts" "maven" "neovim" "nodejs"
  "npm" "obs-studio" "obsidian" "proton-vpn-gtk-app" "qbittorrent" "rsync" "rust" "rust-bindgen" "rust-src" "rustup" "snapper" "ufw" "vim" "zsh" "ttf-firacode-nerd")

flatpak_packages=("neo.ankiweb.Anki" "org.localsend.localsend_app" "org.telegram.desktop")

aur_packages=("brave-bin")

### INSTALL ###

# Install Flatpak and Add Flathub as the repository
sudo pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install yay AUR helper
mkdir /tmp/yay-build
git clone https://aur.archlinux.org/yay.git /tmp/yay-build
cd /tmp/yay-build || exit
sudo makepkg -si --noconfirm
cd /home/"$USER" || exit

# Update all repos
sudo pacman -Syu --noconfirm
flatpak update -y

# Install pacman packages
for i in "${pacman_packages[@]}"; do
  sudo pacman -S "${i}" --noconfirm
done

# Install Flatpaks
for i in "${flatpak_packages[@]}"; do
  flatpak install flathub "${i}" -y
done

# Install AUR packages
for i in "${aur_packages[@]}"; do
  yay -S "${i}" --noconfirm
done

# Install OpenCode
curl -fsSL https://opencode.ai/install | bash

### CONFIGURATION ###

# Backup Grub before we f*ck it all up
if [ ! -f /etc/default/grub.bak ]; then
  sudo cp /etc/default/grub /etc/default/grub.bak
fi

# Configure UFW
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

#Configure AppArmor
if ! grep -q "apparmor=1 security=apparmor" /etc/default/grub; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 apparmor=1 security=apparmor"/' /etc/default/grub
fi
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo mkdir -p /var/cache/apparmor
if ! pacman -Q apparmor-profiles &>/dev/null; then
  sudo pacman -S --noconfirm apparmor-profiles 2>/dev/null || echo "Note: apparmor-profiles package not available or installation skipped"
fi
if [ -d /etc/apparmor.d ]; then
  sudo apparmor_parser -r /etc/apparmor.d/* 2>/dev/null || true
fi
if ! pacman -Q audit &>/dev/null; then
  sudo pacman -S --noconfirm audit
  sudo systemctl enable auditd.service
else
  sudo systemctl enable auditd.service
fi

# Set the LTS kernel as the default
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Configure the terminal environment
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

# Add starshp to terminal
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# TODO: Pull from git dotfile repo for ghostty and ZSH config

# Install Lazyvim
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak."$(date +%s)"
fi
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Create my three main special directors
mkdir /home/"$USER"/Univesrsity
mkdir /home/"$USER"/ObsidianVault
mkdir /home/"$USER"/Projects
mkdir /home/"$USER"/Scripts

# Clone my script directory
git clone https://github.com/matthewlabrecque/automation-scripts.git /home/"$USER"/Scripts/

# Set my Git credentials
git config --global user.name "Matthew Labrecque"
git config --global user.email "matthew.labrecque@proton.me"Pull my scripts repo to my scripts folder
