set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Starting full cleanup ==="

bash "$SCRIPT_DIR/pacman-cache.sh"

bash "$SCRIPT_DIR/orphans.sh"

bash "$SCRIPT_DIR/journal.sh"

bash "$SCRIPT_DIR/thumbnails.sh"

rm -rf "${HOME}/.cache/"*/ 2>/dev/null || true

if command -v notify-send &>/dev/null; then
    notify-send "System Cleaner" "Full system cleanup completed!" &
fi

echo "=== Full cleanup finished ==="
