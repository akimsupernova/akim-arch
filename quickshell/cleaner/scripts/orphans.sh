set -uo pipefail

orphans=$(pacman -Qtdq 2>/dev/null || true)

if [[ -n "$orphans" ]]; then
    pkexec pacman -Rns --noconfirm $orphans
    msg="Orphan packages removed"
else
    msg="No orphan packages found"
fi

if command -v notify-send &>/dev/null; then
    notify-send "System Cleaner" "$msg" &
fi
