#!/usr/bin/env bash
# Put a ZeeShell foot theme in place, but only if this foot accepts it.
#   put-foot-theme.sh <destination> <new theme file>
# foot refuses to start on a config it cannot read, so the new file is checked
# first. Older foot releases call the colour section [colors]; if the modern
# names are rejected the file is rewritten for those and checked again.
dest="$1"
new="$2"
[ -f "$new" ] || exit 1

ok() { foot --check-config --config="$1" >/dev/null 2>&1; }

if command -v foot >/dev/null 2>&1 && ! ok "$new"; then
    sed -i -e 's/^\[colors-dark\]$/[colors]/' -e '/^\[colors-light\]$/,$d' "$new"
    if ! ok "$new"; then
        rm -f "$new"
        exit 1
    fi
fi
mv -f "$new" "$dest"
