#!/bin/bash

echo "==> Installing required packages..."
pacman -Sy --noconfirm linux grub efibootmgr

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
```
