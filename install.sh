#!/bin/bash

# ============================================================
#                     AKIMPNG ARCH INSTALLER
# ============================================================
#
#  Custom Arch installation script by akimpng
#
#  Logic:
#    1. Download akimpng.tar.gz from Hugging Face
#    2. Extract it to a temporary directory
#    3. Move /mnt/install/* to /mnt
#    4. Generate fstab
#    5. Enter the installed system using arch-chroot
#
# ============================================================

set -e
set -o pipefail

# -----------------------------
# Colors
# -----------------------------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# -----------------------------
# Configuration
# -----------------------------
HF_BASE_URL="https://huggingface.co/datasets/akimpng/archprebuild/resolve/main"
PARTS=(aa ab ac ad ae af ag ah)

DOWNLOAD_DIR="/mnt/123"
EXTRACT_DIR="/mnt/124"

# -----------------------------
# Functions
# -----------------------------

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

# -----------------------------
# Banner
# -----------------------------

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

# -----------------------------
# Check root
# -----------------------------

if [ "$EUID" -ne 0 ]; then
    error_exit "This script must be run as root."
fi

success "Running as root."

# -----------------------------
# Check internet connection
# -----------------------------

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

# -----------------------------
# Prepare directories
# -----------------------------

info "Preparing temporary directories..."

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

success "Temporary directories ready."

# -----------------------------
# Download prebuild
# -----------------------------

echo
echo "============================================================"
echo "                     DOWNLOADING ARCH"
echo "============================================================"
echo

info "Downloading prebuild files (${#PARTS[@]} parts)..."
echo

# Max attempts per part before giving up (each attempt resumes, not restarts)
MAX_RETRIES=30
# Seconds to wait between retry attempts
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

        # -C -   : resume from where the last attempt left off (needs no restart on a dropped connection)
        # --retry: let curl itself retry on transient network errors within one attempt
        # --speed-limit/--speed-time: only abort on a genuine stall (near-zero throughput for 2 minutes
        #   straight), not on a connection that is merely slow but still making progress
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

# -----------------------------
# Extract prebuild
# -----------------------------

echo "============================================================"
echo "                    EXTRACTING FILE"
echo "============================================================"
echo

info "Extracting system file directly from split parts..."

if ! cat "${PART_FILES[@]}" | tar -xvzpf - -C "$EXTRACT_DIR"; then
    error_exit "Failed to extract the archive from split parts."
fi

success "System extracted successfully."

info "Removing downloaded part files..."
rm -f "${PART_FILES[@]}"
success "Part files removed."

# -----------------------------
# Move installed system
# -----------------------------

echo
echo "============================================================"
echo "                  RESTORING ARCH SYSTEM"
echo "============================================================"
echo

if [ ! -d "$EXTRACT_DIR/mnt/install" ]; then
    error_exit "Expected directory $EXTRACT_DIR/mnt/install was not found inside the archive."
fi

info "Moving installed system files to /mnt..."

if ! mv "$EXTRACT_DIR/mnt/install/"* /mnt/; then
    error_exit "Failed to move the installed system to /mnt."
fi

success "Arch system restored to /mnt."

# -----------------------------
# Cleanup
# -----------------------------

info "Cleaning temporary files..."

rm -rf "$DOWNLOAD_DIR"
rm -rf "$EXTRACT_DIR"

success "Temporary files removed."

echo
echo "============================================================"
echo "                       COMPLETE"
echo "============================================================"
echo

echo -e "${GREEN}Arch installation environment is ready.${RESET}"
echo
echo -e "${CYAN}Created by akimpng${RESET}"
echo

echo "============================================================"
echo "                     NEXT STEPS"
echo "============================================================"
echo
echo -e "${YELLOW}The system files are in place, but a few manual steps"
echo -e "are still needed before you can boot into it.${RESET}"
echo

echo -e "${CYAN}1) Mount your EFI partition${RESET}"
echo "   Replace /dev/sdXn with your actual EFI partition."
echo
echo -e "   ${GREEN}mount /dev/sdXn /mnt/boot/efi${RESET}"
echo

echo -e "${CYAN}2) Generate the fstab${RESET}"
echo "   This tells the system which partitions to mount at boot."
echo
echo -e "   ${GREEN}genfstab -U /mnt >> /mnt/etc/fstab${RESET}"
echo

echo -e "${CYAN}3) Enter the new system${RESET}"
echo "   Chroot into /mnt to finish configuration (bootloader,"
echo "   hostname, users, etc.)."
echo
echo -e "   ${GREEN}arch-chroot /mnt${RESET}"
echo

echo "============================================================"
echo
