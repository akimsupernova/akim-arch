<p align="center">
  <img src="screenshot/Screenshot_2026-09-21_22.32.44.png" alt="akimpng Arch Desktop" width="100%">
</p>

# Arch Custom Installer

A simple Arch Linux install script that downloads a prebuild system.

> **IMPORTANT: This script is designed to be run from the Arch Linux Live environment.**

# READ THIS BEFORE INSTALLING

This is a **system restore script**, not a traditional Arch Linux installer.

The script restores the prebuild system into the filesystem mounted at:

```text
/mnt
```

**DO NOT run this script from an already installed Arch Linux system.**

This script is intended to be run from a **fresh Arch Linux Live environment**.

## Environment Login

**Default credentials** for the prebuilt system:

- **Username:** `live`
- **Password:** `live`
- **Root password:** `live`

> Please change the default password after the first login.

# TARGET FILESYSTEM

The target installation filesystem must be mounted at:

```text
/mnt
```

Verify:

```bash
findmnt /mnt
```

Check the filesystem type:

```bash
findmnt -no FSTYPE /mnt
```

Expected:

```text
btrfs
```

You can also check the available space:

```bash
df -h /mnt
```

> **WARNING:** Make absolutely sure `/mnt` points to the correct disk/partition before running the script.

The script will install the system directly into `/mnt`.

# EFI SYSTEM PARTITION

A UEFI installation requires an **EFI System Partition (ESP)**.

The EFI partition must be available at:

```text
/boot/efi
```

> **IMPORTANT:** Do **NOT** mount the EFI System Partition to `/mnt/boot/efi` before the system install.
>
> The prebuild filesystem already contains `/boot/efi`. If the ESP is mounted at `/mnt/boot/efi` before the restore, the mounted filesystem can hide the `/boot/efi` directory from the system and cause the restore to conflict with the existing EFI filesystem contents.
>
> The ESP must therefore be mounted **only after `install.sh` has finished restoring the system**, right before you generate `fstab` and enter `arch-chroot` (the script prints these steps for you at the end).

# INSTALLATION

Download [Arch Linux ISO](https://archlinux.org/download/) flash it to your usb drive and boot into it. Make sure disable **Secure Boot**.

The Arch Linux Live ISO does not include `git` by default. Install it first:

```bash
pacman -Sy git
```

Clone this repository:

```bash
git clone https://github.com/akimsupernova/akim-arch
```

Enter the repository:

```bash
cd akim-arch
```

Run the installer:

```bash
./install.sh
```

When it's done, it does **not** mount the EFI partition, generate `fstab`, or enter `arch-chroot` automatically — it prints the exact commands for those steps so you can run each one yourself, in order.

# AFTER THE SCRIPT FINISHES

**THE INSTALLATION IS NOT FINISHED YET.**

Follow the three steps `install.sh` prints at the end, in this exact order.

## Step 1 — Mount the EFI partition

**This is the required point to mount the EFI System Partition** — now that the restore is finished, but before generating `fstab` or entering the chroot.

```bash
mount /dev/your-efi-partition /mnt/boot/efi
```

Verify:

```bash
findmnt /mnt/boot/efi
```

It must show the EFI System Partition.

> **IMPORTANT:** The EFI partition is intentionally mounted here, **after the system has been restored**. Do not mount it at `/mnt/boot/efi` before running the restore.

## Step 2 — Generate fstab

Mounting the ESP first means it gets included correctly in `fstab`:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## Step 3 — Enter the chroot

```bash
arch-chroot /mnt
```

You are now inside the restored system.

## Change username and password

After restoring the system, the default user is `live`
Follow the steps below to rename the user and set a new password.
```bash
usermod -l your_name live
```
```bash
usermod -d /home/your_name -m your_name
```
```bash
groupmod -n your_name live
```
```bash
sed -i 's/User=live/User=your_name/' /etc/sddm.conf
```

Password.
```bash
passwd your_name
```

# BOOTLOADER INSTALLATION IS REQUIRED

**THE EASY WAY: USE `efibootmgr`**

The restored system already has **`efibootmgr` and GRUB pre-installed**, so you do not need to install them again.

For the easiest UEFI boot setup, you can use `efibootmgr` to create a UEFI boot entry that points directly to the existing GRUB EFI loader.

First verify that the EFI System Partition is mounted **from inside the chroot**:

```bash
findmnt /boot/efi
```

Create a UEFI boot entry with:

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
```

After that:

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

> **NOTE:** `efibootmgr` creates the UEFI firmware boot entry. It does not install GRUB itself. In this restore workflow, GRUB is already present in the restored system, which is why `efibootmgr` can be used as the easy way to register it with the UEFI firmware.

If you prefer to reinstall/configure GRUB manually, you can still use the standard GRUB UEFI installation method for your system.

After the bootloader has been installed and configured:

```bash
exit
```

Then reboot:

```bash
reboot
```

Remove the Arch Linux USB/ISO when the system starts rebooting.

# NVIDIA GPU NOTE

If you have an **NVIDIA GPU**, driver setup is not guaranteed to work out of the box.

You may need to **troubleshoot the NVIDIA driver yourself** after first boot (proprietary vs open kernel modules, Wayland/Hyprland-specific env vars, etc.). This restore image is not tuned for every NVIDIA configuration, so check the [Arch Wiki NVIDIA page](https://wiki.archlinux.org/title/NVIDIA) and the [Hyprland NVIDIA guide](https://wiki.hypr.land/Nvidia/) if you run into graphical issues, black screens, or tearing.

# MONITOR CONFIGURATION (Hyprland)

The desktop environment is **Hyprland**. Monitor setup (resolution, refresh rate, position, scaling) is configured at:

```text
/home/live/.config/hypr/hyprland/general.lua
```

Edit this file to match your monitor(s). For a full guide on the available options and syntax, see the official Hyprland docs:

**[https://wiki.hypr.land/Configuring/Basics/Monitors/](https://wiki.hypr.land/Configuring/Basics/Monitors/)**

# KEYBINDINGS

> **Super** = `SUPER` / Windows key

## Shell & UI

| Keybind | Action |
|---|---|
| `Super` | Toggle search |
| `Super + Tab` | Workspace overview |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + A` | Left sidebar |
| `Super + N` | Right sidebar |
| `Super + B` | Toggle cleaner |
| `Super + /` | Keybind cheatsheet |
| `Super + K` | On-screen keyboard |
| `Super + M` | Media controls |
| `Super + G` | Widget overlay |
| `Super + J` | Toggle bar |
| `Ctrl + Alt + Delete` | Session menu |
| `Super + L` | Lock screen |
| `Super + Shift + L` | Suspend |

## Applications

| Keybind | Action |
|---|---|
| `Super + Enter` / `Super + T` | Terminal |
| `Super + E` | File manager |
| `Super + W` | Browser |
| `Super + C` | Code editor |
| `Ctrl + Super + V` | Volume mixer |
| `Super + I` | Settings |
| `Ctrl + Shift + Esc` | Task manager |
| `Ctrl + Super + Shift + Alt + W` | Office |

## Windows

| Keybind | Action |
|---|---|
| `Super + Left/Right/Up/Down` | Focus window |
| `Super + Shift + Left/Right/Up/Down` | Move window |
| `Super + Left Click` | Move window |
| `Super + Right Click` | Resize window |
| `Super + Q` | Close window |
| `Super + Shift + Alt + Q` | Force close window |
| `Super + Alt + Space` | Float / tile |
| `Super + D` | Maximize |
| `Super + F` | Fullscreen |
| `Super + Alt + F` | Fullscreen spoof |
| `Super + P` | Pin window |
| `Super + ;` / `Super + '` | Adjust split ratio |
| `Super + Alt + 1–0` | Send window to workspace 1–10 |
| `Super + Alt + S` | Send window to scratchpad |
| `Ctrl + Super + S` | Toggle scratchpad |
| `Ctrl + Super + Backslash` | Resize window to 640×480 |

## Workspaces

| Keybind | Action |
|---|---|
| `Super + 1–0` | Switch to workspace 1–10 |
| `Ctrl + Super + Left/Right` | Previous / next workspace |
| `Super + Page Up/Down` | Previous / next workspace |
| `Ctrl + Super + Page Up/Down` | Previous / next workspace |
| `Super + S` | Toggle scratchpad |

## Screenshots & Capture

| Keybind | Action |
|---|---|
| `Super + Space` | Screenshot → clipboard |
| `Ctrl + Super + Space` | Screenshot → file |
| `Super + Shift + S` | Region screenshot |
| `Super + Shift + A` | Region search |
| `Super + Shift + X` | OCR selected region |
| `Super + Shift + T` | Translate screen |
| `Super + Shift + C` | Color picker |
| `Super + Shift + R` | Record region |
| `Super + Alt + R` | Record region |
| `Ctrl + Alt + R` | Record fullscreen |
| `Super + Shift + Alt + R` | Record fullscreen + sound |

## Media & Audio

| Keybind | Action |
|---|---|
| `Super + Shift + N` | Next track |
| `Super + Shift + B` | Previous track |
| `Super + Shift + M` | Toggle audio mute |
| `Super + Alt + M` | Toggle microphone mute |
| `Super + Shift + P` | Shutdown |
| `Super + Scroll Mouse Up` | Volume up |
| `Super + Scroll Mouse Down` | Volume down |

## Screen & Appearance

| Keybind | Action |
|---|---|
| `Super + -` | Zoom out |
| `Super + =` | Zoom in |
| `Ctrl + Super + T` | Wallpaper selector |
| `Ctrl + Super + Alt + T` | Random wallpaper |
| `Ctrl + Super + Shift + D` | Toggle light / dark mode |
| `Ctrl + Super + R` | Restart widgets |
| `Ctrl + Super + P` | Cycle panel family |

## Virtual Machine Mode

| Keybind | Action |
|---|---|
| `Super + Alt + F1` | Enter / exit VM mode |

When VM mode is active, other keybindings are disabled until `Super + Alt + F1` is pressed again.

## Credits

The Hyprland and desktop configuration in this project is based on
dotfiles originally created by [end-4](https://github.com/end-4).

The original dotfiles have been substantially modified and extended
for this project.

Modified and maintained by [Akim](https://github.com/akimsupernova).

Additional work includes:
- Custom Arch Linux installation and system restore scripts
- Additional tools and packages
- System configuration
- Desktop environment configuration
- Modified dotfiles and workflows

This project is distributed under the GNU General Public License v3.0.
See [LICENSE](LICENSE) for the full license text.
