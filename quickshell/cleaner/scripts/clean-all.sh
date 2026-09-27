#!/bin/bash
set -uo pipefail

echo "=== Starting full cleanup ==="

orphans=$(pacman -Qtdq 2>/dev/null || true)

root_cmds=""

if command -v paccache &>/dev/null; then
    root_cmds+="paccache -rk2; "
else
    root_cmds+="pacman -Scc --noconfirm; "
fi

if [[ -n "$orphans" ]]; then
    root_cmds+="pacman -Rns --noconfirm $orphans; "
fi

root_cmds+="journalctl --vacuum-time=7d; "
root_cmds+="rm -rf /root/.cache; "
root_cmds+="rm -rf /tmp/*; "

pkexec bash -c "$root_cmds"

rm -rf "${HOME}/.cache/"*/ 2>/dev/null || true

if command -v notify-send &>/dev/null; then
    notify-send "System Cleaner" "Full system cleanup completed!" &
fi

echo "=== Full cleanup finished ==="
