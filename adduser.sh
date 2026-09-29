#!/bin/bash
# Bikin user baru di sistem yang di-mount di /mnt (tanpa arch-chroot)

ROOT="/mnt"

# harus dijalankan sebagai root (default di Arch live USB)
if [[ $EUID -ne 0 ]]; then
    echo "Jalankan script ini sebagai root."
    exit 1
fi

# pastikan /mnt sudah berisi sistem
if [[ ! -f "$ROOT/etc/passwd" ]]; then
    echo "Sistem belum ditemukan di $ROOT. Mount partisi root dulu."
    exit 1
fi

read -rp "enter your new username: " username

# validasi format username
if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
    echo "Username tidak valid. Pakai huruf kecil, angka, _ atau -, dan tidak boleh diawali angka."
    exit 1
fi

# cek apakah user sudah ada
if grep -q "^${username}:" "$ROOT/etc/passwd"; then
    echo "User '$username' sudah ada."
    exit 1
fi

# buat user + home directory, masuk grup wheel
useradd -R "$ROOT" -m -G wheel -s /bin/bash "$username" || exit 1

# set password
echo "Set password untuk $username:"
passwd -R "$ROOT" "$username"

echo "User '$username' berhasil dibuat."
