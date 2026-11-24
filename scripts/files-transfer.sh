#!/usr/bin/env bash
# Copy or move files into a folder for the ZeeShell file explorer.
#   files-transfer.sh <destination folder> <copy|move> <path>...
# Nothing is ever overwritten: when a name is taken, the new item becomes
# "name (2).ext", "name (3).ext", and so on.
dest="$1"
mode="$2"
shift 2

[ -d "$dest" ] || { echo "Not a folder: $dest" >&2; exit 1; }
status=0

for src in "$@"; do
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        echo "No longer there: $src" >&2
        status=1
        continue
    fi
    base="$(basename -- "$src")"
    target="$dest/$base"

    # Moving something onto itself is a no-op, not a rename.
    if [ "$mode" = move ] && [ "$(dirname -- "$(realpath -s -- "$src")")" = "$(realpath -s -- "$dest")" ]; then
        continue
    fi
    # A folder cannot go inside itself.
    case "$(realpath -s -- "$dest")/" in
        "$(realpath -s -- "$src")"/*)
            echo "Cannot put \"$base\" inside itself" >&2
            status=1
            continue
            ;;
    esac

    if [ -e "$target" ] || [ -L "$target" ]; then
        stem="$base"
        ext=""
        if [ ! -d "$src" ]; then
            case "$base" in
                ?*.tar.?*) stem="${base%.tar.*}"; ext=".tar.${base##*.}" ;;
                ?*.*) stem="${base%.*}"; ext=".${base##*.}" ;;
            esac
        fi
        n=2
        while [ -e "$dest/$stem ($n)$ext" ] || [ -L "$dest/$stem ($n)$ext" ]; do
            n=$((n + 1))
        done
        target="$dest/$stem ($n)$ext"
    fi

    if [ "$mode" = move ]; then
        mv -- "$src" "$target" || status=1
    else
        cp -a -- "$src" "$target" || status=1
    fi
done

exit "$status"
