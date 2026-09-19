# akimpng Arch Installer

A simple Arch Linux restore/install script that downloads a system backup from Google Drive, extracts it to `/mnt`, generates `fstab`, and enters the installed system using `arch-chroot`.

> **⚠️ IMPORTANT: This script is designed to be run from the official Arch Linux Live ISO.**

---

# ⚠️ READ THIS BEFORE INSTALLING

This is a **system restore script**, not a traditional Arch Linux installer.

The backup was originally created from a system installed on a **16 GB drive**.

**The original 16 GB drive size does NOT mean that your target installation disk must also be 16 GB.**

You can restore the system to a larger disk.

For example:

```text
Original backup:
16 GB filesystem
        │
        ▼
      BACKUP
        │
        ▼
Target disk:
64 GB / 128 GB / 256 GB / 1 TB
```

The script restores the **contents of the backup** into the filesystem mounted at `/mnt`.

It does **not** resize your disk or recreate your partition layout.

---

# 💾 TARGET DISK SIZE

Before running the script, **you are responsible for creating the target partitions and filesystem.**

The target filesystem should already be mounted at:

```text
/mnt
```

The size of `/mnt` can be different from the original 16 GB filesystem.

For example:

```text
Original:
16 GB

Target:
64 GB    ✅
128 GB   ✅
256 GB   ✅
512 GB   ✅
1 TB     ✅
```

The important requirement is that the target filesystem has enough **usable free space** to contain the restored system.

---

## ⚠️ DO NOT COPY THE ORIGINAL 16 GB PARTITION LAYOUT

**DO NOT assume that the backup requires you to recreate the original 16 GB disk layout.**

You should create the partition layout appropriate for **your own disk**.

For example, a new installation could have:

```text
EFI System Partition
        │
        └── /boot/efi

Btrfs partition
        │
        └── /
            mounted at /mnt
```

The Btrfs partition can be significantly larger than the original 16 GB filesystem.

---

# ⚠️ VERY IMPORTANT: TARGET `/mnt`

Before running the script, verify that `/mnt` is the filesystem where you actually want the restored system to be installed.

Check:

```bash
findmnt /mnt
```

Then check the filesystem type:

```bash
findmnt -no FSTYPE /mnt
```

Expected:

```text
btrfs
```

You can also check available space:

```bash
df -h /mnt
```

Make sure there is enough free space for the restored system.

---

# 📦 HOW THE RESTORE WORKS

The process is approximately:

```text
Google Drive
     │
     │  akimpng.tar.gz
     ▼
/mnt/123
     │
     │  extract
     ▼
/mnt/124
     │
     │  restore
     ▼
/mnt
     │
     ▼
Restored Arch System
```

The backup contains the **filesystem contents**, not a requirement that the destination disk must be exactly 16 GB.

The destination filesystem is the one you mounted at `/mnt`.

---

# ⚠️ IMPORTANT: DO NOT RESTORE TO A TARGET THAT IS TOO SMALL

Although the original system came from a 16 GB drive, the compressed archive may contain a substantial amount of data.

Therefore, **do not determine the required target size only from the original disk size.**

Check the available space on your target:

```bash
df -h /mnt
```

If the target filesystem does not have enough usable space, extraction may fail.

A larger target disk is recommended.

---

# ⚠️ IMPORTANT: BTRFS

The target filesystem mounted at `/mnt` must be **Btrfs**.

Verify:

```bash
findmnt -no FSTYPE /mnt
```

Expected:

```text
btrfs
```

If you get something else:

```text
ext4
xfs
ntfs
...
```

**STOP.**

Do not continue until `/mnt` is correctly prepared as Btrfs.

---

# 🥾 EFI SYSTEM PARTITION

You also need an **EFI System Partition (ESP)** for a UEFI installation.

The restored system expects the EFI partition to be available at:

```text
/boot/efi
```

After entering the restored system:

```bash
arch-chroot /mnt
```

check:

```bash
findmnt /boot/efi
```

If `/boot/efi` is not mounted correctly:

> **DO NOT REBOOT. DO NOT FINISH THE INSTALLATION.**

Make sure the EFI partition is correctly mounted before installing/configuring your bootloader.

---

# 🚀 INSTALLATION

Boot from the **official Arch Linux ISO**.

Make sure you are in the Arch Live environment and have root access.

Check your disks:

```bash
lsblk -f
```

Create your desired partition layout.

Then format and mount the target filesystem as appropriate for your installation.

For example:

```bash
mount /dev/your-btrfs-partition /mnt
```

Verify:

```bash
findmnt /mnt
```

Verify Btrfs:

```bash
findmnt -no FSTYPE /mnt
```

Then verify available space:

```bash
df -h /mnt
```

Make sure the EFI System Partition is also prepared for:

```text
/mnt/boot/efi
```

---

## 🌐 Check Internet

```bash
ping -c 3 archlinux.org
```

Then clone the repository:

```bash
git clone https://github.com/akimsupernova/akim-arch.git
```

Enter the repository:

```bash
cd akim-arch
```

Make the script executable:

```bash
chmod +x pull.sh
```

Run:

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
5. Download the system backup.
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

# ⚠️ AFTER `arch-chroot`

**THE INSTALLATION IS NOT FINISHED.**

When the script enters:

```bash
arch-chroot /mnt
```

you are inside the restored system.

You still need to verify:

```bash
findmnt /boot/efi
```

Then check:

```bash
cat /etc/fstab
```

After that, **install and configure your bootloader**.

The backup does not magically make the new disk bootable just because the filesystem was restored.

Your bootloader must be correctly installed for the **new installation's EFI partition**.

---

# ⚠️ FINAL CHECKLIST

Before running `./pull.sh`:

* [ ] Booted from the **official Arch Linux ISO**
* [ ] Running in the **Arch Live environment**
* [ ] Running as root
* [ ] Internet connection works
* [ ] Correct target disk has been identified
* [ ] Target filesystem is mounted at `/mnt`
* [ ] `/mnt` is **Btrfs**
* [ ] Target filesystem is large enough for the restored system
* [ ] You understand that the backup originally came from a **16 GB drive**
* [ ] You understand that the target disk **does NOT need to be 16 GB**
* [ ] EFI System Partition exists
* [ ] EFI partition is prepared for `/boot/efi`
* [ ] You have verified that `/mnt` is the correct target

After `arch-chroot`:

* [ ] `/boot/efi` is mounted correctly
* [ ] `/etc/fstab` has been checked
* [ ] Bootloader has been installed
* [ ] Bootloader configuration has been completed
* [ ] System is ready to boot from the new disk

---

# 🧑‍💻 Credits

**AKIMPNG**

Created by **akimpng**.

**AKIMPNG ARCH RESTORE WORKFLOW**

The goal of this project is to make restoring an Arch Linux system from a backup as simple and portable as possible.
