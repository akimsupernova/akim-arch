set -uo pipefail

rm -rf "${HOME}/.cache/thumbnails" 2>/dev/null || true

if command -v notify-send &>/dev/null; then
    notify-send "System Cleaner" "Thumbnail cache cleared!" &
fi
