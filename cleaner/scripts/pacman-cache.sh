set -uo pipefail

if command -v paccache &>/dev/null; then
    pkexec paccache -rk2
else
    pkexec pacman -Sc --noconfirm
fi

if command -v notify-send &>/dev/null; then
    notify-send "System Cleaner" "Pacman cache cleaned!" &
fi
