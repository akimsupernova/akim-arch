#!/usr/bin/env python3

import argparse
import os
import re
import sys

DEFAULT_PATH = os.path.expanduser("~/.config/hypr/hyprland/general.lua")
BLOCK_RE = re.compile(r"hl\.monitor\(\{(.*?)\}\)", re.DOTALL)


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--file", default=DEFAULT_PATH,
                    help="Path to general.lua (default: %(default)s)")
    p.add_argument("--output", required=True, help='Output name, exp. "HDMI-A-1"')
    p.add_argument("--mode", required=True, help='exp. "1920x1080@120"')
    p.add_argument("--position", required=True, help='exp. "0x0"')
    p.add_argument("--scale", required=True, help='exp. "1.00"')
    return p.parse_args()


def set_field(body: str, key: str, value: str, quoted: bool) -> str:
    val_str = f'"{value}"' if quoted else value
    pattern = re.compile(rf'({re.escape(key)}\s*=\s*)("[^"]*"|[^,\n]+)')
    if pattern.search(body):
        return pattern.sub(lambda m: f"{m.group(1)}{val_str}", body, count=1)
    stripped = body.rstrip()
    if stripped and not stripped.endswith(","):
        stripped += ","
    return stripped + f"\n    {key} = {val_str},\n"


def build_new_block(output: str, mode: str, position: str, scale: str) -> str:
    return (
        "hl.monitor({\n"
        f'    output = "{output}",\n'
        f'    mode = "{mode}",\n'
        f'    position = "{position}",\n'
        f"    scale = {scale},\n"
        "})\n"
    )


def main():
    args = parse_args()
    path = args.file

    if not os.path.isfile(path):
        print(f"ERROR: im tired boss, i cant find the file TT: {path}", file=sys.stderr)
        sys.exit(1)

    with open(path, "r") as f:
        original = f.read()

    content = original
    matches = list(BLOCK_RE.finditer(content))

    target_span = None
    target_body = None
    for m in matches:
        body = m.group(1)
        om = re.search(r'output\s*=\s*"([^"]*)"', body)
        if om and om.group(1) == args.output:
            target_span = m.span()
            target_body = body
            break

    if target_body is not None:
        new_body = target_body
        new_body = set_field(new_body, "mode", args.mode, quoted=True)
        new_body = set_field(new_body, "position", args.position, quoted=True)
        new_body = set_field(new_body, "scale", args.scale, quoted=False)
        new_block = "hl.monitor({" + new_body + "})"
        start, end = target_span
        content = content[:start] + new_block + content[end:]
    else:
        new_block = build_new_block(args.output, args.mode, args.position, args.scale)
        if matches:
            insert_at = matches[-1].end()
            nl = content.find("\n", insert_at)
            insert_at = nl + 1 if nl >= 0 else insert_at
            content = content[:insert_at] + new_block + content[insert_at:]
        else:
            content = new_block + "\n" + content

    if content == original:
        print("OK (Nothing)")
        return

    backup_path = path + ".bak"
    with open(backup_path, "w") as f:
        f.write(original)

    with open(path, "w") as f:
        f.write(content)

    print("OK")


if __name__ == "__main__":
    main()
