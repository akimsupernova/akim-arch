```bash
#!/bin/bash

# ============================================================
#                     AKIMPNG ARCH INSTALLER
# ============================================================
#
#  Custom Arch installation script by akimpng
#
#  Logic:
#    1. Download backup.tar.gz from Google Drive
#    2. Extract it to a temporary directory
#    3. Move /mnt/install/* to /mnt
#    4. Generate fstab
#    5. Enter the installed system using arch-chroot
#
# ============================================================

set -e

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
FILE_ID="1PWqpZOt-i9_h7QILTqy7RcqaeSC-Azdt"

DOWNLOAD_DIR="/mnt/123"
EXTRACT_DIR="/mnt/124"
BACKUP_FILE="${DOWNLOAD_DIR}/akimpng.tar.gz"

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
echo "                 AKIMPNG ARCH INSTALLER"
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

if ! ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
    warning "Internet connection appears to be unavailable."
    echo
    echo "This installer requires an active internet connection"
    echo "to download the Arch backup from Google Drive."
    echo
    echo "Please check your network connection and run the script again."
    echo
    exit 1
fi

success "Internet connection is available."

# -----------------------------
# Install required tools
# -----------------------------

info "Installing required tools..."

if ! pacman -Sy --needed --noconfirm python-pip; then
    error_exit "Failed to install python-pip. Check your internet connection or pacman configuration."
fi

success "python-pip is ready."

# -----------------------------
# Install gdown
# -----------------------------

info "Checking gdown..."

if ! command -v gdown >/dev/null 2>&1; then
    info "gdown is not installed. Installing it now..."

    if ! pip install --break-system-packages gdown; then
        error_exit "Failed to install gdown."
    fi

    success "gdown installed."
else
    success "gdown is already installed."
fi

# -----------------------------
# Prepare directories
# -----------------------------

info "Preparing temporary directories..."

mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

success "Temporary directories ready."

# -----------------------------
# Download backup
# -----------------------------

echo
echo "============================================================"
echo "                 DOWNLOADING ARCH BACKUP"
echo "============================================================"
echo

info "Downloading backup from Google Drive..."
info "Destination: $BACKUP_FILE"
echo

if ! gdown "https://drive.google.com/uc?id=${FILE_ID}" -O "$BACKUP_FILE"; then
    echo
    warning "Google Drive download failed."
    echo
    echo "Possible causes:"
    echo "  - Internet connection was lost"
    echo "  - Google Drive is unavailable"
    echo "  - The file is no longer publicly accessible"
    echo "  - The Google Drive file ID is invalid"
    echo
    error_exit "Unable to download the Arch backup."
fi

if [ ! -f "$BACKUP_FILE" ]; then
    error_exit "Download finished but the backup file was not found."
fi

success "Backup downloaded successfully."

echo
echo "Backup size:"
ls -lh "$BACKUP_FILE"
echo

# -----------------------------
# Extract backup
# -----------------------------

echo "============================================================"
echo "                    EXTRACTING BACKUP"
echo "============================================================"
echo

info "Extracting backup to $EXTRACT_DIR..."

if ! tar -xvzpf "$BACKUP_FILE" -C "$EXTRACT_DIR"; then
    error_exit "Failed to extract the backup archive."
fi

success "Backup extracted successfully."

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

# -----------------------------
# Generate fstab
# -----------------------------

echo
echo "============================================================"
echo "                    GENERATING FSTAB"
echo "============================================================"
echo

info "Generating /mnt/etc/fstab..."

if ! genfstab -U /mnt >> /mnt/etc/fstab; then
    error_exit "Failed to generate fstab."
fi

success "fstab generated successfully."

# -----------------------------
# Finish
# -----------------------------

echo
echo "============================================================"
echo "                       COMPLETE"
echo "============================================================"
echo

echo -e "${GREEN}Arch installation environment is ready.${RESET}"
echo
echo "Entering arch-chroot..."
echo
echo -e "${CYAN}Created by akimpng${RESET}"
echo

# -----------------------------
# Enter chroot
# -----------------------------

arch-chroot /mnt
```
