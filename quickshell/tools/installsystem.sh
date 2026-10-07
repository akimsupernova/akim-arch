#!/bin/bash

while true; do
    read -rp "Do you want to use the CachyOS repository? [y/n]: " answer

    case "$answer" in
        [Yy])
            echo
            echo "==> Setting up CachyOS repository..."

            pacman -Sy --noconfirm --needed curl tar git

            mkdir -p /tmp/cachyos-setup
            cd /tmp/cachyos-setup || exit 1

            curl -fL https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz || {
                echo "!! Failed to download CachyOS repo."
                exit 1
            }

            tar xvf cachyos-repo.tar.xz && cd cachyos-repo || exit 1
            ./cachyos-repo.sh

            cd /
            rm -rf /tmp/cachyos-setup

            echo
            echo "==> Installing CachyOS kernel..."
            pacman -Sy --noconfirm linux-cachyos linux-cachyos-headers grub efibootmgr

            echo
            echo "==> CachyOS repository and kernel installed."
            break
            ;;

        [Nn])
            echo "==> Installing required packages..."
            pacman -Sy --noconfirm linux linux-headers grub efibootmgr
            break
            ;;

        *)
            echo "Please answer y or n."
            ;;
    esac
done

echo
echo "==> Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux

echo
echo "==> Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "========================================"
echo " GRUB installation completed."
echo "========================================"
echo

while true; do
    read -rp "Do you also want to install the GRUB theme? [y/n]: " answer

    case "$answer" in
        [Yy])
            echo
            echo "==> Installing GRUB theme..."

            cd /tmp

            rm -rf akim-grub-theme
            git clone https://github.com/akimsupernova/akim-grub-theme

            cd akim-grub-theme
            ./setup install

            cd /
            rm -rf /tmp/akim-grub-theme

            echo
            echo "==> GRUB theme installed successfully."
            break
            ;;

        [Nn])
            echo
            echo "==> Skipping GRUB theme."
            break
            ;;

        *)
            echo "Please answer y or n."
            ;;
    esac
done

echo
echo "========================================"
echo "  Installation completed successfully!"
echo "========================================"
