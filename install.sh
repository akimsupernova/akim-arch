#!/bin/bash

set -e
set -o pipefail

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

HF_BASE_URL="https://huggingface.co/datasets/akimpng/archprebuild/resolve/main"
PARTS=(aa ab ac ad ae af ag)

DOWNLOAD_DIR="/mnt/123"
EXTRACT_DIR="/mnt/124"

error_exit() {
    echo
    echo -e "${RED}[ERROR]${RESET} $1"
    echo
    echo -e "${YELLOW}Installation cannot continue.${RESET}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

clear

echo -e "${CYAN}"
echo "============================================================"
echo "                  AKIMPNG ARCH INSTALLER"
echo "============================================================"
echo -e "${RESET}"

echo "        Custom Arch deployment script"
echo "        Created by akimpng"
echo
echo "============================================================"
echo

if [ "$EUID" -ne 0 ]; then
    error_exit "This script must be run as root."
fi

success "Running as root."

# ------------------------------------------------------------
# Pre-flight: /mnt and /mnt/boot must already be mounted
# ------------------------------------------------------------

info "Checking target mounts..."

if ! mountpoint -q /mnt; then
    error_exit "/mnt is not a mount point.
Mount your Btrfs system partition first:
  mount /dev/your-system-partition /mnt"
fi

ROOT_FSTYPE="$(findmnt -no FSTYPE /mnt)"
if [ "$ROOT_FSTYPE" != "btrfs" ]; then
    error_exit "/mnt must be a Btrfs filesystem (found: ${ROOT_FSTYPE:-unknown})."
fi

if [ ! -d /mnt/boot ]; then
    error_exit "/mnt/boot does not exist.
Create it and mount your EFI partition before running this script:
  mkdir -p /mnt/boot
  mount /dev/your-efi-partition /mnt/boot"
fi

if ! mountpoint -q /mnt/boot; then
    error_exit "/mnt/boot exists but nothing is mounted on it.
Mount your EFI partition first:
  mount /dev/your-efi-partition /mnt/boot"
fi

BOOT_FSTYPE="$(findmnt -no FSTYPE /mnt/boot)"
if [ "$BOOT_FSTYPE" != "vfat" ]; then
    error_exit "/mnt/boot must be a FAT32 (vfat) EFI partition (found: ${BOOT_FSTYPE:-unknown})."
fi

if [ "$(findmnt -no SOURCE /mnt)" = "$(findmnt -no SOURCE /mnt/boot)" ]; then
    error_exit "/mnt and /mnt/boot are mounted from the same device. Use separate partitions."
fi

success "/mnt is Btrfs and /mnt/boot is a mounted EFI partition."

# ------------------------------------------------------------
# Internet
# ------------------------------------------------------------

info "Checking internet connection..."

INTERNET_OK=false
for i in 1 2 3 4 5; do
    if ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        INTERNET_OK=true
        break
    fi
    sleep 2
done

if [ "$INTERNET_OK" != "true" ]; then
    warning "Internet connection appears to be unavailable."
    echo
    echo "This installer requires an active internet connection"
    echo "to download the prebuild Arch system from Hugging Face."
    echo
    echo "Please check your network connection and run the script again."
    echo
    exit 1
fi

success "Internet connection is available."

info "Preparing temporary directories..."

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

success "Temporary directories ready."

echo
echo "============================================================"
echo "                     DOWNLOADING ARCH"
echo "============================================================"
echo

info "Downloading prebuild files (${#PARTS[@]} parts)..."
echo

MAX_RETRIES=30
RETRY_DELAY=5

PART_FILES=()

for PART in "${PARTS[@]}"; do
    PART_FILE="${DOWNLOAD_DIR}/akimpng.tar.gz.part.${PART}"
    PART_URL="${HF_BASE_URL}/akimpng.tar.gz.part.${PART}"

    info "Downloading part ${PART}..."

    ATTEMPT=1
    DOWNLOAD_OK=false

    while [ "$ATTEMPT" -le "$MAX_RETRIES" ]; do
        if [ "$ATTEMPT" -gt 1 ]; then
            warning "Retrying part ${PART} (attempt ${ATTEMPT}/${MAX_RETRIES})..."
            sleep "$RETRY_DELAY"
        fi

        if curl -L --fail -C - \
                --retry 5 --retry-delay 5 --retry-connrefused \
                --speed-limit 50 --speed-time 120 \
                -o "$PART_FILE" "$PART_URL"; then
            DOWNLOAD_OK=true
            break
        fi

        ATTEMPT=$((ATTEMPT + 1))
    done

    if [ "$DOWNLOAD_OK" != "true" ]; then
        echo
        warning "Prebuild part download failed: ${PART}"
        echo
        echo "Possible causes:"
        echo "  - Internet connection was lost"
        echo "  - The file is no longer publicly accessible"
        echo "  - The URL is invalid"
        echo
        error_exit "Unable to download the prebuild system (part ${PART}) after ${MAX_RETRIES} attempts."
    fi

    if [ ! -f "$PART_FILE" ]; then
        error_exit "Download finished but part ${PART} was not found."
    fi

    success "Part ${PART} downloaded."
    PART_FILES+=("$PART_FILE")
done

success "All parts downloaded successfully."

echo
echo "Prebuild parts size:"
ls -lh "${PART_FILES[@]}"
echo

echo "============================================================"
echo "                    EXTRACTING FILE"
echo "============================================================"
echo

info "Extracting system file directly from split parts..."

if ! cat "${PART_FILES[@]}" | tar -xvzpf - --numeric-owner -C "$EXTRACT_DIR"; then
    error_exit "Failed to extract the archive from split parts."
fi

success "System extracted successfully."

info "Removing downloaded part files..."
rm -f "${PART_FILES[@]}"
success "Part files removed."

echo
echo "============================================================"
echo "                  INSTALLED ARCH SYSTEM"
echo "============================================================"
echo

SRC_DIR="$EXTRACT_DIR/mnt/install"

if [ ! -d "$SRC_DIR" ]; then
    error_exit "Expected directory $SRC_DIR was not found inside the archive."
fi

info "Moving installed system files to /mnt..."

# The prebuild intentionally has no /boot: it is the EFI partition that was
# mounted at /mnt/boot beforehand. If one shows up, it would collide with
# that mount point, so stop instead of guessing.
if [ -e "$SRC_DIR/boot" ]; then
    error_exit "The prebuild archive contains a /boot directory, which conflicts with the mounted EFI partition at /mnt/boot."
fi

# dotglob so hidden files/directories in the root are moved too.
shopt -s dotglob nullglob
for ITEM in "$SRC_DIR"/*; do
    if ! mv "$ITEM" /mnt/; then
        error_exit "Failed to move $(basename "$ITEM") to /mnt."
    fi
done
shopt -u dotglob nullglob

success "Arch system installed to /mnt."

pacstrap -K /mnt linux

info "Generating fstab..."

if ! genfstab -U /mnt > /mnt/etc/fstab; then
    error_exit "Failed to generate /mnt/etc/fstab."
fi

success "fstab generated."

info "Cleaning temporary files..."

rm -rf "$DOWNLOAD_DIR"
rm -rf "$EXTRACT_DIR"

success "Temporary files removed."

echo
echo "============================================================"
echo "                        COMPLETE"
echo "============================================================"
echo

echo -e "${GREEN}Arch installation environment is ready.${RESET}"
echo
echo -e "${CYAN}Created by akimpng${RESET}"
echo

echo "============================================================"
echo "                       NEXT STEPS"
echo "============================================================"
echo
echo -e "${YELLOW}The system files and fstab are in place. Only two steps remain.${RESET}"
echo

echo -e "${CYAN}1) Enter the new system${RESET}"
echo
echo -e "   ${GREEN}arch-chroot /mnt${RESET}"
echo

echo -e "${CYAN}2) Finish the installation${RESET}"
echo "   Checks for missing files, downloads them with pacman, and"
echo "   builds/installs the bootloader to the EFI partition at /boot."
echo "   (needs an internet connection)"
echo
echo -e "   ${GREEN}installsystem${RESET}"
echo

echo "============================================================"
echo
