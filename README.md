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

From the Arch Live environment, it should be mounted to:

```text
/mnt/boot/efi
```

For example:

```bash
mkdir -p /mnt/boot/efi
mount /dev/your-efi-partition /mnt/boot/efi
```

Verify:

```bash
findmnt /mnt/boot/efi
```

You should see the EFI System Partition mounted there.

> **⚠️ WARNING:** Do not continue if the EFI partition is not correctly mounted.

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

Prepare the EFI partition:

```bash
mkdir -p /mnt/boot/efi
mount /dev/your-efi-partition /mnt/boot/efi
```

Verify:

```bash
findmnt /mnt/boot/efi
```

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

Make sure the script is executable:

```bash
chmod +x pull.sh
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
13. Generate `/mnt/etc/fstab`.
14. Enter the restored system using `arch-chroot`.

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

You must still verify the EFI partition:

```bash
findmnt /boot/efi
```

It must show the EFI System Partition.

Then check the generated filesystem table:

```bash
cat /etc/fstab
```

---

# 🥾 BOOTLOADER INSTALLATION IS REQUIRED

**DO NOT REBOOT YET.**

The restore process does **NOT** guarantee that the new installation is bootable.

You must still:

1. Verify `/boot/efi`
2. Check `/etc/fstab`
3. Install your bootloader
4. Configure the bootloader
5. Verify that the bootloader installation completed successfully

For example, if you use **systemd-boot**, install and configure systemd-boot according to your system configuration.

If you use **GRUB**, install and configure GRUB for UEFI.

> **⚠️ WARNING: `arch-chroot` does NOT mean the installation is complete.**
>
> **DO NOT reboot until the bootloader has been installed and configured.**

---

# ⚠️ BEFORE REBOOTING

Inside the chroot, verify:

```bash
findmnt /boot/efi
```

Then:

```bash
cat /etc/fstab
```

Make sure the required filesystems and EFI mount are correct.

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
* [ ] EFI partition is mounted at `/mnt/boot/efi`
* [ ] `/mnt` has been verified as the correct installation target

## After `arch-chroot`

* [ ] `/boot/efi` is mounted correctly
* [ ] `/etc/fstab` has been checked
* [ ] Bootloader has been installed
* [ ] Bootloader configuration has been completed
* [ ] System is ready to boot

---

# 🧑‍💻 Credits

**AKIMPNG**

Created by **akimpng**.

**AKIMPNG ARCH RESTORE WORKFLOW**

The goal of this project is to make restoring an Arch Linux system as simple and straightforward as possible.
