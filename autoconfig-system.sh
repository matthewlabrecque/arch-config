#!/bin/bash
set -euo pipefail

pacman_packages=("apparmor" "base-devel" "btrfs-assistant" "btop" "clang" "distrobox" "element-desktop" "fastfetch" "gcc" "ghostty" "go" "gnome-keyring" "gradle" "jdk-openjdk" "jre-openjdk" "lazygit" "libreoffice-still" "linux-lts" "maven" "neovim" "nodejs"
  "npm" "obs-studio" "obsidian" "podman" "proton-vpn-gtk-app" "qbittorrent" "rclone" "rust" "rust-bindgen" "rust-src" "rustup" "snapper" "telegram-desktop" "ufw" "vim" "vlc" "zsh" "ttf-firacode-nerd")

aur_packages=("brave-bin" "localsend" "visual-studio-code-bin")

flatpak_packages=("neo.ankiweb.Anki")

### INSTALL ###

# Install Flatpak and Add Flathub as the repository
sudo pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install yay AUR helper
mkdir /tmp/yay-build
git clone https://aur.archlinux.org/yay.git /tmp/yay-build
cd /tmp/yay-build || exit
makepkg -si
cd /home/"$USER" || exit

# Update all repos
sudo pacman -Syu --noconfirm
flatpak update -y --noninteractive

# Install pacman packages
for i in "${pacman_packages[@]}"; do
  sudo pacman -S "${i}" --noconfirm
done

# Install AUR packages
for i in "${aur_packages[@]}"; do
  yay -S "${i}" --noconfirm
done

# Install Flatpaks
for i in "${flatpak_packages[@]}"; do
  flatpak install flathub "${i}" --noninteractive
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
# TODO: Add in default AppArmor configuration

# Configure the terminal environment
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

# Add starshp to terminal
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Create my three main special directors
mkdir -p /home/"$USER"/Univesrsity
mkdir -p /home/"$USER"/ObsidianVault
mkdir -p /home/"$USER"/Repos

# Append to .zshrc
sudo tee -a """
# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi


# Enable starship
eval '$(starship init zsh)'

# Custom aliases
alias ll='ls -lF'
alias vim='nvim'
alias lgit='lazygit'
alias htop='btop'

# opencode
export PATH=/home/'$USER'/.opencode/bin:$PATH""" /home/"$USER"/.zshrc

# Pull from git dotfile repo
mkdir -p /tmp/dotfiles
git clone https://github.com/matthewlabrecque/dotfiles.git /tmp/dotfiles
cd /home/"$USER"/

# If the ghostty config doesn't exist, creat the directory
# Otherwise, remove the config
if [ ! -f ~/.config/ghostty/config ]; then
  mkdir -p ~/.config/ghostty/config
elif [ -f ~/.config/ghostty/config ]; then
  rm .config/ghostty/config
fi

# If the fastfech config doesn't exist, create the directory
# Otherwise, remove the config
if [ ! -f ~/.config/fastfetch/config.jsonc ]; then
  mkdir -p ~/.config/fastfetch
elif [ -f ~/.config/fastfetch/config.jsonc ]; then
  rm .config/fastfetch/config.jsonc
fi

cd /tmp/dotfiles
cp fastfetch_config.jsonc /home/"$USER"/.config/fastfetch/config.jsonc
cp ghostty_config /home/"$USER"/.config/ghostty/config
cd /home/"$USER"/

# Install Lazyvim
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak."$(date +%s)"
fi
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Reboot the system
sudo reboot
