set -uo pipefail

pkexec journalctl --vacuum-time=7d

if command -v notify-send &>/dev/null; then
    notify-send "System Cleaner" "Journal cleaned (kept last 7 days)!" &
fi
