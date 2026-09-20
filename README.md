<p align="center">
  <img src="screenshot/Screenshot_2026-09-20_10.04.07.png" alt="akimpng Arch Desktop" width="100%">
</p>

# akimpng Arch Installer

A simple Arch Linux restore/install script that downloads a system backup from Google Drive, extracts it to `/mnt`, generates `fstab`, and enters the installed system using `arch-chroot`.

> **⚠️ IMPORTANT: This script is designed to be run from the Arch Linux Live environment.**

---

# ⚠️ READ THIS BEFORE INSTALLING

This is a **system restore script**, not a traditional Arch Linux installer.

The script restores the backup into the filesystem mounted at:

```text
/mnt
```

**DO NOT run this script from an already installed Arch Linux system.**

This script is intended to be run from a **fresh Arch Linux Live environment**.

---

# 🔐 ENVIRONMENT LOGIN

For the environment used with this workflow:

```text
Username: live
Password: live
Root password: live
```

---

# ⚠️ REQUIREMENTS

Before running the script, make sure:

* You booted into the **Arch Linux Live ISO**
* You are working in the Live environment
* You have root access
* Internet connection is working
* The target filesystem is mounted at `/mnt`
* The target filesystem is **Btrfs**
* An EFI System Partition exists
* The EFI System Partition is prepared for `/boot/efi`
* You have verified that `/mnt` is the correct installation target

---

# 💾 TARGET FILESYSTEM

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

> **⚠️ WARNING:** Make absolutely sure `/mnt` points to the correct disk/partition before running the script.

The script will restore the system directly into `/mnt`.

---

# 🥾 EFI SYSTEM PARTITION

A UEFI installation requires an **EFI System Partition (ESP)**.

The EFI partition must be available at:

```text
/boot/efi
```

> **⚠️ IMPORTANT:** Do **NOT** mount the EFI System Partition to `/mnt/boot/efi` before the backup restore.
>
> The backup filesystem already contains `/boot/efi`. If the ESP is mounted at `/mnt/boot/efi` before the restore, the mounted filesystem can hide the `/boot/efi` directory from the backup and cause the restore to conflict with the existing EFI filesystem contents.
>
> The ESP must therefore be mounted **only after the backup has finished restoring and after entering `arch-chroot`**.

---

# 🚀 INSTALLATION

Boot the computer from the **Arch Linux Live ISO**.

Make sure you are inside the Live environment.

Check your disks:

```bash
lsblk -f
```

Mount your target Btrfs filesystem:

```bash
mount /dev/your-btrfs-partition /mnt
```

Verify:

```bash
findmnt /mnt
```

Verify that it is Btrfs:

```bash
findmnt -no FSTYPE /mnt
```

Expected:

```text
btrfs
```

> **⚠️ DO NOT MOUNT THE EFI PARTITION HERE**
>
> At this point `/mnt` must contain only the target filesystem. Do **not** mount the ESP to `/mnt/boot/efi` yet.
>
> The restore process must first restore the backup, including its `/boot/efi` directory, without another filesystem mounted over it.

---

# 🌐 CHECK INTERNET

Make sure the Live environment has internet access:

```bash
ping -c 3 archlinux.org
```

If the internet connection is unavailable, **DO NOT continue**.

The script needs internet access to download the backup from Google Drive.

---

# 📥 DOWNLOAD THE INSTALLER

Clone the repository:

```bash
git clone https://github.com/akimsupernova/akim-arch.git
```

Enter the repository:

```bash
cd akim-arch
```

Run the installer:

```bash
./pull.sh
```

---

# 🔄 WHAT THE SCRIPT DOES

The script will:

1. Check that it is running as root.
2. Check internet connectivity.
3. Install the required tools.
4. Install `gdown` if necessary.
5. Download the system backup from Google Drive.
6. Create `/mnt/123`.
7. Download the backup to `/mnt/123/akimpng.tar.gz`.
8. Create `/mnt/124`.
9. Extract the backup into `/mnt/124`.
10. Restore the system contents into `/mnt`.
11. Remove `/mnt/123`.
12. Remove `/mnt/124`.
13. Enter the restored system using `arch-chroot`.
14. Mount the EFI System Partition at `/boot/efi` from inside the chroot.
15. Generate or verify `/etc/fstab` after the EFI partition is mounted.

---

# 📁 TEMPORARY DIRECTORIES

During the restore process, the script creates:

```text
/mnt/123
/mnt/124
```

The downloaded backup is stored temporarily at:

```text
/mnt/123/akimpng.tar.gz
```

The archive is temporarily extracted into:

```text
/mnt/124
```

These temporary directories are removed after the restore process.

---

# ⚠️ AFTER `arch-chroot`

**THE INSTALLATION IS NOT FINISHED YET.**

When the script enters:

```bash
arch-chroot /mnt
```

you are now inside the restored system.

## 🥾 Mount the EFI partition AFTER the restore

**This is the required point to mount the EFI System Partition.**

Inside the chroot:

```bash
mount /dev/your-efi-partition /boot/efi
```

Verify:

```bash
findmnt /boot/efi
```

It must show the EFI System Partition.

> **⚠️ IMPORTANT:** The EFI partition is intentionally mounted here, **after the backup has been restored**. Do not mount it at `/mnt/boot/efi` before running the restore.

# 🥾 BOOTLOADER INSTALLATION IS REQUIRED

**DO NOT REBOOT YET.**

The restore process does **NOT** guarantee that the new installation is bootable.

You must still:

1. Verify `/boot/efi`
2. Check `/etc/fstab`
3. Install your bootloader
4. Configure the bootloader
5. Verify that the bootloader installation completed successfully

> **💡 THE EASY WAY: USE `efibootmgr`**
>
> The restored system already has **`efibootmgr` and GRUB pre-installed**, so you do not need to install them again.
>
> For the easiest UEFI boot setup, you can use `efibootmgr` to create a UEFI boot entry that points directly to the existing GRUB EFI loader.

## ⚡ EASY BOOTLOADER SETUP WITH `efibootmgr`

First verify that the EFI System Partition is mounted **from inside the chroot**:

```bash
findmnt /boot/efi
```

Then verify that GRUB's EFI loader exists:

```bash
ls /boot/efi/EFI/GRUB/grubx64.efi
```

If the file exists, create a UEFI boot entry with:

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
```

After that:

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

> **💡 NOTE:** `efibootmgr` creates the UEFI firmware boot entry. It does not install GRUB itself. In this restore workflow, GRUB is already present in the restored system, which is why `efibootmgr` can be used as the easy way to register it with the UEFI firmware.

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

---

# ⚠️ FINAL CHECKLIST

## Before running `./pull.sh`

* [ ] Booted from the **Arch Linux Live ISO**
* [ ] Running in the **Live environment**
* [ ] Live username is `live`
* [ ] Live user password is `live`
* [ ] Root password is `live`
* [ ] Running as root
* [ ] Internet connection works
* [ ] Correct target disk has been identified
* [ ] Target filesystem is mounted at `/mnt`
* [ ] `/mnt` is **Btrfs**
* [ ] EFI System Partition exists
* [ ] EFI partition is **NOT mounted at `/mnt/boot/efi`**
* [ ] `/mnt` has been verified as the correct installation target

## After `arch-chroot`

* [ ] Backup restore has completed
* [ ] `/boot/efi` directory from the backup is present
* [ ] EFI System Partition is mounted at `/boot/efi`
* [ ] `/etc/fstab` has been checked/generated with the ESP mounted
* [ ] Bootloader has been installed
* [ ] Bootloader configuration has been completed
* [ ] System is ready to boot

---

# 🧑‍💻 Credits

**AKIMPNG**

Created by **akimpng**.

**AKIMPNG ARCH RESTORE WORKFLOW**

The goal of this project is to make restoring an Arch Linux system as simple and straightforward as possible.
