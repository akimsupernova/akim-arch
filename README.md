<p align="center">
  <img src="screenshot/Screenshot_2026-09-21_22.32.44.png" alt="akimpng Arch Desktop" width="100%">
</p>

# Arch Custom Installer

A simple Arch Linux install script that downloads a prebuild system.

> **IMPORTANT: This script is designed to be run from the Arch Linux Live environment.**

# READ THIS BEFORE INSTALLING

This is a **system install script**, not a traditional Arch Linux installer.

The script install the prebuild system into the filesystem mounted at:

```text
/mnt
```

**DO NOT run this script from an already installed Arch Linux system.**

This script is intended to be run from a **fresh Arch Linux Live environment**.

## Environment Login

**Default credentials** for the prebuilt system:

- **Username:** `arch`
- **Password:** `arch`
- **Root password:** `arch`

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

# FIRST WHAT YOU NEED

Download the [Arch Linux ISO](https://archlinux.org/download/) flash it to your usb drive, for windows user use [rufus](https://rufus.ie/en/) or [ventoy](https://www.ventoy.net/en/download.html) and boot into it. Make sure to disable **Secure Boot**.

# PARTITIONING AND FORMATTING

Before running `install.sh`, create the EFI System Partition and the Btrfs system partition from the Arch Linux Live environment.

> **WARNING:** The commands below will erase the selected partitions. Double-check the target disk with `lsblk` before continuing.

## Step 1 — Identify the target disk

List the available disks:

```bash
lsblk
```

For example, if the target disk is `/dev/nvme0n1`, use that disk with `cfdisk`.

> **IMPORTANT:** Your device name may be different. SATA drives commonly appear as `/dev/sda`, while NVMe drives commonly appear as `/dev/nvme0n1`.

## Step 2 — Create partitions with cfdisk

Open `cfdisk` on the target disk:

```bash
cfdisk /dev/nvme0n1
```

If prompted for a partition table, select:

```text
gpt
```

Create the following two partitions:

| Partition | Recommended size | Type | Filesystem |
|---|---:|---|---|
| EFI System Partition | 1 GiB | EFI System | FAT32 |
| System | Remaining space | Linux filesystem | Btrfs |

In `cfdisk`:

1. Select **Free space** or **Delete** the partition that you dont need anymore and choose **New**.
2. Create a `1G` partition for the EFI System Partition.
3. Select the new EFI partition, choose **Type**, and set it to **EFI System**.
4. Select the remaining **Free space** and choose **New**.
5. Use the remaining space for the Btrfs system partition.
6. Choose **Write**, type `yes`, and press Enter.
7. Choose **Quit**.

Verify the resulting partition layout:

```bash
lsblk
```

For an NVMe disk, it should look similar to:

```text
nvme0n1
├─nvme0n1p1   1G
└─nvme0n1p2   remaining space
```

## Step 3 — Format the EFI partition as FAT32

Replace `/dev/nvme0n1p1` with your actual EFI partition:

```bash
mkfs.fat -F32 /dev/nvme0n1p1
```

Verify:

```bash
lsblk -f
```

The EFI partition should show `vfat` / `FAT32`.

## Step 4 — Format the system partition as Btrfs

Replace `/dev/nvme0n1p2` with your actual Btrfs system partition:

```bash
mkfs.btrfs -f /dev/nvme0n1p2
```

Verify:

```bash
lsblk -f
```

The system partition should show `btrfs`.

## Step 5 — Mount the Btrfs system partition

Mount the Btrfs system partition at `/mnt`:

```bash
mount /dev/nvme0n1p2 /mnt
```

Verify:

```bash
findmnt /mnt
```

Check the filesystem type:

```bash
findmnt -no FSTYPE /mnt
```

It must return:

```text
btrfs
```

> **IMPORTANT:** Do **NOT** mount the EFI System Partition to `/mnt/boot/efi` before the system install.
>
> The prebuild filesystem already contains `/boot/efi`. If the ESP is mounted at `/mnt/boot/efi` before the install, the mounted filesystem can hide the `/boot/efi` directory from the system and cause the install to conflict with the existing EFI filesystem contents.
>
> The ESP must therefore be mounted **only after `install.sh` has finished restoring the system**, right before you generate `fstab` and enter `arch-chroot` (the script prints these steps for you at the end).

# INSTALLATION

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

**This is the required point to mount the EFI System Partition** — now that the install is finished, but before generating `fstab` or entering the chroot.

```bash
mount /dev/your-efi-partition /mnt/boot/efi
```

Verify:

```bash
findmnt /mnt/boot/efi
```

It must show the EFI System Partition.

> **IMPORTANT:** The EFI partition is intentionally mounted here, **after the system has been installed**. Do not mount it at `/mnt/boot/efi` before running the install

## Step 2 — Generate fstab

Mounting the ESP first means it gets included correctly in `fstab`:

```bash
genfstab -U /mnt > /mnt/etc/fstab
```

## Step 3 — Enter the chroot

```bash
arch-chroot /mnt
```

You are now inside the installed system.

## Change password

After restoring the system, the default password is `arch`

Change it.
```bash
passwd arch
```
Root password.
```bash
passwd
```

## Changing the username

If you also want to change the default `arch` username, see the [Arch Wiki guide](https://wiki.archlinux.org/title/Users_and_groups#Renaming_a_user) on renaming a user:

> **WARNING:** Changing the username is **not recommended**. The prebuilt dotfiles and desktop configuration in this system are built and hardcoded around the existing `arch` user (paths like `/home/arch/.config/...`, systemd user services, permissions, etc.). Renaming the user can break these references.
>
> If you rename the user anyway, any resulting **config file conflicts, broken paths, or non-working dotfiles are your own responsibility**.

# BOOTLOADER INSTALLATION IS REQUIRED

**THE EASY WAY: USE `efibootmgr`**

The installed system already has **`efibootmgr` and GRUB pre-installed**, so you do not need to install them again.

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

> **NOTE:** `efibootmgr` creates the UEFI firmware boot entry. It does not install GRUB itself. GRUB is already present in the system, which is why `efibootmgr` can be used as the easy way to register it with the UEFI firmware.

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

You may need to **troubleshoot the NVIDIA driver yourself** after first boot (proprietary vs open kernel modules, Wayland/Hyprland-specific env vars, etc.). This system image is not tuned for every NVIDIA configuration, so check the [Arch Wiki NVIDIA page](https://wiki.archlinux.org/title/NVIDIA) and the [Hyprland NVIDIA guide](https://wiki.hypr.land/Nvidia/) if you run into graphical issues, black screens, or tearing.

# MONITOR CONFIGURATION

The desktop environment is **Hyprland**. Monitor configuration (resolution, refresh rate, position, scaling) can be managed directly from the desktop.

To change your monitor resolution or other display settings, press:

```text
Super + T
```

This opens the **Monitor Configuration** interface, where you can adjust the monitor settings without manually editing the Hyprland configuration.

The monitor settings are also configured through the Hyprland configuration at:

```text
/home/arch/.config/hypr/hyprland/general.lua
```

For a full guide on the available Hyprland monitor options and syntax, see the official Hyprland docs:

**https://wiki.hypr.land/Configuring/Basics/Monitors/**

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
| `Super + Alt + A` | Detach left sidebar |
| `Super + B` | Toggle cleaner |
| `Super + /` | Keybind cheatsheet |
| `Super + K` | On-screen keyboard |
| `Super + M` | Media controls |
| `Super + G` | Widget overlay |
| `Super + J` | Toggle bar |
| `Ctrl + Alt + Delete` | Session menu |
| `Super + N` | Right sidebar |
| `Super + Alt + K` | Calculator |

## Applications

| Keybind | Action |
|---|---|
| `Super + Enter` | Terminal |
| `Ctrl + Alt + T` | Terminal |
| `Super + E` | File manager |
| `Super + W` | Browser |
| `Super + C` | Code editor |
| `Super + X` | Steam |
| `Ctrl + Super + V` | Volume mixer |
| `Super + I` | Settings app |
| `Ctrl + Shift + Esc` | Task manager |
| `Ctrl + Super + Shift + Alt + W` | Office software |
| `Super + T` | Monitor Configuration |

## Windows

| Keybind | Action |
|---|---|
| `Super + Left/Right/Up/Down` | Focus window |
| `Super + Shift + Left/Right/Up/Down` | Move window |
| `Super + Left Click` | Move window |
| `Super + Right Click` | Resize window |
| `Alt + F4` | Show wrong-close-key notification |
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
| `Ctrl + Super + Alt + Left/Right` | Focus busy workspace left / right |
| `Super + Page Up/Down` | Previous / next workspace |
| `Ctrl + Super + Page Up/Down` | Previous / next workspace |
| `Ctrl + Super + BracketLeft/BracketRight` | Focus adjacent workspace |
| `Ctrl + Super + Up/Down` | Focus workspace 5 positions left / right |
| `Super + S` | Toggle scratchpad |
| `Super + mouse side button` | Toggle scratchpad |

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
| `Super + Scroll Up/Down` | Adjust volume |

## Screen & Appearance

| Keybind | Action |
|---|---|
| `Super + -` | Zoom out |
| `Super + =` | Zoom in |
| `Ctrl + Super + T` | Wallpaper selector / color switch |
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
[dotfiles](https://github.com/end-4/dots-hyprland) originally created by [end-4](https://github.com/end-4).

The original dotfiles have been substantially modified and extended
for this project.

Modified and maintained by [Akim](https://github.com/akimsupernova).

Additional work includes:
- Custom Arch Linux installation and system install scripts
- Additional tools and packages
- System configuration
- Desktop environment configuration
- Modified dotfiles and workflows

This project is distributed under the GNU General Public License v3.0.
See [LICENSE](LICENSE) for the full license text.
