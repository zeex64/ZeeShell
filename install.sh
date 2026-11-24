#!/usr/bin/env bash
# ZeeShell installer.
#
#   ./install.sh               copy the shell into ~/.config/quickshell/zeeshell,
#                              add the `zeeshell` command, and hook up Hyprland
#   ./install.sh --link        symlink this folder instead of copying (for
#                              working on the shell: edits apply live)
#   ./install.sh --uninstall   take all of that back out again
#
# Nothing here needs root. Files it changes are backed up first, and a second
# run changes nothing that is already in place.

set -euo pipefail

SRC="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="$CONFIG/quickshell/zeeshell"
BIN="$HOME/.local/bin"
HYPR="$CONFIG/hypr"
HOOKS="$HYPR/zeeshell"
MARKER=".installed-by-zeeshell"
STAMP="$(date +%Y%m%d-%H%M%S)"

# What a copy install takes from the repo. Everything else is for the repo only.
PAYLOAD=(shell.qml files.qml config components services modules scripts assets themes zeeshell LICENSE)

ACTION=install
MODE=copy
WITH_HYPR=auto
WITH_TERMINAL=yes
DRY=0
FORCE=0
PURGE=0
RELOAD=1
START=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

  (no options)     Install: copy the shell, add the `zeeshell` command, and
                   connect it to Hyprland (autostart and default keybinds).
  --link           Symlink this folder instead of copying it.
  --no-hyprland    Leave the Hyprland config alone.
  --no-terminal    Leave terminals alone: no kitty/foot theme, no greeter.
  --start          Start the shell when the install is done.
  --no-reload      Do not run `hyprctl reload` afterwards.
  --force          Replace an existing install folder this script did not make.
  --dry-run        Show what would happen without changing anything.
  --uninstall      Remove the shell, the command and the Hyprland hooks.
  --purge          With --uninstall: also remove your settings, your keybind
                   file and the cache.
  -h, --help       Show this help.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --link) MODE=link ;;
        --no-hyprland) WITH_HYPR=no ;;
        --no-terminal) WITH_TERMINAL=no ;;
        --start) START=1 ;;
        --no-reload) RELOAD=0 ;;
        --force) FORCE=1 ;;
        --dry-run) DRY=1 ;;
        --uninstall) ACTION=uninstall ;;
        --purge) PURGE=1 ;;
        -h | --help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [ -t 1 ]; then
    BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; GREEN=$'\e[32m'; OFF=$'\e[0m'
else
    BOLD=""; DIM=""; RED=""; YELLOW=""; GREEN=""; OFF=""
fi

# Show paths the way people write them.
nice() { printf '%s' "${1/#$HOME/\~}"; }

# A backup name that is not taken yet.
backup_name() {
    local base="$1.before-zeeshell-$STAMP" name n=1
    name="$base"
    while [ -e "$name" ]; do
        n=$((n + 1))
        name="$base-$n"
    done
    printf '%s' "$name"
}

step() { printf '\n%s%s%s\n' "$BOLD" "$1" "$OFF"; }
info() { printf '  %s\n' "$1"; }
good() { printf '  %s✓%s %s\n' "$GREEN" "$OFF" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$OFF" "$1"; }
fail() { printf '%sError:%s %s\n' "$RED" "$OFF" "$1" >&2; exit 1; }

# Run a command, or only print it under --dry-run.
run() {
    if [ "$DRY" = 1 ]; then
        printf '  %swould run:%s %s\n' "$DIM" "$OFF" "$*"
    else
        "$@"
    fi
}

# Replace a file with new content from stdin, keeping a backup of the old one.
# Does nothing when the content is already the same.
write_file() {
    local target="$1" tmp
    tmp="$(mktemp)"
    cat > "$tmp"
    if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
        rm -f "$tmp"
        return 1
    fi
    if [ "$DRY" = 1 ]; then
        printf '  %swould change:%s %s\n' "$DIM" "$OFF" "$(nice "$target")"
        rm -f "$tmp"
        return 0
    fi
    if [ -f "$target" ]; then
        local keep
        keep="$(backup_name "$target")"
        cp -p "$target" "$keep"
        info "Backup: $(nice "$keep")"
    fi
    cat "$tmp" > "$target"
    rm -f "$tmp"
    return 0
}

# Print a file without the blocks this script added, and without the blank
# lines left at either end.
strip_blocks() {
    local file="$1" prefix="$2"
    awk -v b="$prefix >>> ZeeShell" -v e="$prefix <<< ZeeShell" '
        index($0, b) == 1 { skip = 1; next }
        index($0, e) == 1 { skip = 0; next }
        !skip { line[++n] = $0 }
        END {
            s = 1; while (s <= n && line[s] ~ /^[[:space:]]*$/) s++
            while (n >= s && line[n] ~ /^[[:space:]]*$/) n--
            for (i = s; i <= n; i++) print line[i]
        }' "$file"
}

has_blocks() { grep -q "^$2 >>> ZeeShell" "$1" 2>/dev/null; }

# ------------------------------------------------------------------ checks

check_requirements() {
    step "Checking what ZeeShell needs"
    local missing=0

    if command -v qs >/dev/null 2>&1; then
        good "Quickshell: $(qs --version 2>/dev/null | head -1)"
    elif command -v quickshell >/dev/null 2>&1; then
        warn "Found \`quickshell\` but not the \`qs\` command the launcher uses. Add a \`qs\` symlink to it."
        missing=1
    else
        warn "Quickshell is not installed (the \`qs\` command). ZeeShell is developed on noctalia-qs."
        missing=1
    fi

    local fonts=""
    command -v fc-list >/dev/null 2>&1 && fonts="$(fc-list : family 2>/dev/null || true)"
    if grep -qi '^Phosphor' <<< "$fonts"; then
        good "Phosphor icon font"
    else
        warn "The Phosphor icon font is missing; every icon would be blank (Arch: ttf-phosphor-icons)."
        missing=1
    fi

    if command -v hyprctl >/dev/null 2>&1; then
        good "Hyprland"
    else
        warn "Hyprland was not found. ZeeShell is built for Hyprland and will not be useful without it."
    fi

    # feature: command(s), any one of which is enough
    local optional=(
        "Wi-Fi and network status:nmcli"
        "Brightness:brightnessctl ddcutil"
        "Night light:gammastep"
        "Screenshot shortcut:hyprshot"
        "Colour picker:hyprpicker"
        "Wallpaper downloads:curl"
        "Colouring KDE apps such as Dolphin:plasma-apply-colorscheme"
        "Connecting drives in the file explorer:udisksctl"
        "Network locations in the file explorer:gio"
        "Opening folders:xdg-open"
        "Session lock password check:unix_chkpwd"
    )
    local entry feature tools tool found
    for entry in "${optional[@]}"; do
        feature="${entry%%:*}"
        tools="${entry#*:}"
        found=""
        for tool in $tools; do
            if command -v "$tool" >/dev/null 2>&1 || [ -x "/usr/bin/$tool" ] || [ -x "/usr/sbin/$tool" ]; then
                found="$tool"
                break
            fi
        done
        [ -n "$found" ] || warn "Optional, for ${feature,}: install ${tools// / or }."
    done

    if [ "$missing" = 1 ]; then
        warn "Installing anyway; the shell will not start properly until the items above are fixed."
    fi
}

# ------------------------------------------------------------------- shell

install_shell() {
    step "Installing the shell to $(nice "$DEST")"

    if [ "$(readlink -f "$DEST" 2>/dev/null || true)" = "$SRC" ] && [ ! -L "$DEST" ]; then
        good "This folder is already the install location; nothing to copy."
    else
        # Clear whatever is there, but only if it is ours.
        if [ -L "$DEST" ]; then
            run rm -f "$DEST"
        elif [ -e "$DEST" ]; then
            if [ -f "$DEST/$MARKER" ] || [ "$FORCE" = 1 ]; then
                run rm -rf "$DEST"
            else
                fail "$(nice "$DEST") already exists and was not created by this installer. Move it away, or pass --force to replace it."
            fi
        fi
        run mkdir -p "$(dirname "$DEST")"

        if [ "$MODE" = link ]; then
            run ln -s "$SRC" "$DEST"
            good "Linked to $(nice "$SRC") (edits there apply live)."
        else
            run mkdir -p "$DEST"
            local item
            for item in "${PAYLOAD[@]}"; do
                [ -e "$SRC/$item" ] || fail "The repository is incomplete: $item is missing."
                run cp -a "$SRC/$item" "$DEST/"
            done
            if [ "$DRY" = 0 ]; then
                printf 'Installed by install.sh on %s from %s\n' "$(date -Iseconds)" "$SRC" > "$DEST/$MARKER"
            fi
            good "Copied."
        fi
    fi

    step "Adding the zeeshell command"
    run mkdir -p "$BIN"
    if [ -e "$BIN/zeeshell" ] && [ ! -L "$BIN/zeeshell" ]; then
        local keep
        keep="$(backup_name "$BIN/zeeshell")"
        run mv "$BIN/zeeshell" "$keep"
        info "Backup: $(nice "$keep")"
    fi
    run ln -sfn "$DEST/zeeshell" "$BIN/zeeshell"
    good "$(nice "$BIN/zeeshell")"
    case ":$PATH:" in
        *":$BIN:"*) ;;
        *) warn "$(nice "$BIN") is not on your PATH, so type the full path, or add it to your shell profile." ;;
    esac
}

# ---------------------------------------------------------------- terminals

MARK_BEGIN="# >>> ZeeShell (added by install.sh; remove with install.sh --uninstall) >>>"
MARK_END="# <<< ZeeShell <<<"

# Append a marked block to a config file (replacing an older copy of it).
# Returns 1 when the file already ends with exactly this block.
add_block() {
    local file="$1" body="$2"
    { strip_blocks "$file" "#"; echo; echo "$MARK_BEGIN"; printf '%s\n' "$body"; echo "$MARK_END"; } | write_file "$file"
}

drop_block() {
    local file="$1"
    [ -f "$file" ] && has_blocks "$file" "#" || return 1
    strip_blocks "$file" "#" | write_file "$file" || true
}

install_terminal() {
    [ "$WITH_TERMINAL" = yes ] || return 0
    step "Setting up your terminals"

    # kitty: a colour file the shell keeps up to date, included from kitty.conf
    if [ -f "$CONFIG/kitty/kitty.conf" ]; then
        [ -f "$CONFIG/kitty/zeeshell.conf" ] || run cp "$SRC/themes/kitty.conf" "$CONFIG/kitty/zeeshell.conf"
        if add_block "$CONFIG/kitty/kitty.conf" "include zeeshell.conf"; then
            good "kitty now uses ZeeShell's colours ($(nice "$CONFIG/kitty/zeeshell.conf"))"
        else
            good "kitty already uses ZeeShell's colours."
        fi
        pkill -USR1 -x kitty 2>/dev/null || true
    fi

    # foot: the same, but foot will not start on a config it cannot read, so
    # the theme is checked before it is hooked up.
    if [ -f "$CONFIG/foot/foot.ini" ]; then
        if [ ! -f "$CONFIG/foot/zeeshell.ini" ] && [ "$DRY" = 0 ]; then
            cp "$SRC/themes/foot.ini" "$CONFIG/foot/zeeshell.ini.new"
            "$SRC/scripts/put-foot-theme.sh" "$CONFIG/foot/zeeshell.ini" "$CONFIG/foot/zeeshell.ini.new" || true
        fi
        if [ -f "$CONFIG/foot/zeeshell.ini" ]; then
            if add_block "$CONFIG/foot/foot.ini" "[main]
include=$CONFIG/foot/zeeshell.ini"; then
                if command -v foot >/dev/null 2>&1 && [ "$DRY" = 0 ] && ! foot --check-config --config="$CONFIG/foot/foot.ini" >/dev/null 2>&1; then
                    drop_block "$CONFIG/foot/foot.ini" || true
                    warn "foot rejected the change, so foot.ini was put back as it was."
                else
                    good "foot now uses ZeeShell's colours in new windows ($(nice "$CONFIG/foot/zeeshell.ini"))"
                fi
            else
                good "foot already uses ZeeShell's colours."
            fi
        elif [ "$DRY" = 0 ]; then
            warn "This foot does not accept ZeeShell's theme file; foot was left alone."
        fi
    fi

    # The greeter: ZeeShell's mark and this machine's specs in new terminals.
    local greet='case $- in *i*) [ -x "$HOME/.local/bin/zeeshell" ] && "$HOME/.local/bin/zeeshell" fetch ;; esac'
    local rc
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        if add_block "$rc" "$greet"; then good "Greeter added to $(nice "$rc")"; else good "$(nice "$rc") already has the greeter."; fi
    done

    if command -v fish >/dev/null 2>&1 || [ -d "$CONFIG/fish" ]; then
        run mkdir -p "$CONFIG/fish/conf.d"
        if cat <<'EOF' | write_file "$CONFIG/fish/conf.d/zeeshell.fish"; then
# Added by ZeeShell's install.sh; removed again by install.sh --uninstall.
# Shows the ZeeShell greeter (the mark and this machine's specs) in new terminals.
if status is-interactive
    function fish_greeting
        test -x ~/.local/bin/zeeshell; and ~/.local/bin/zeeshell fetch
    end
end
EOF
            good "Greeter added for fish ($(nice "$CONFIG/fish/conf.d/zeeshell.fish"))"
        else
            good "fish already has the greeter."
        fi
        # A greeting defined in config.fish would win over ours; step it aside.
        if [ -f "$CONFIG/fish/config.fish" ] && grep -q '^function fish_greeting\b' "$CONFIG/fish/config.fish"; then
            if sed 's/^function fish_greeting\b\(.*\)$/function fish_greeting_before_zeeshell\1 # renamed by ZeeShell install.sh/' "$CONFIG/fish/config.fish" | write_file "$CONFIG/fish/config.fish"; then
                good "Your old fish greeting is kept as fish_greeting_before_zeeshell."
            fi
        fi
    fi
}

remove_terminal() {
    local f
    for f in "$CONFIG/kitty/kitty.conf" "$CONFIG/foot/foot.ini" "$HOME/.bashrc" "$HOME/.zshrc"; do
        if drop_block "$f"; then good "Removed ZeeShell's lines from $(nice "$f")"; fi
    done
    pkill -USR1 -x kitty 2>/dev/null || true
    for f in "$CONFIG/kitty/zeeshell.conf" "$CONFIG/foot/zeeshell.ini" "$CONFIG/fish/conf.d/zeeshell.fish"; do
        if [ -e "$f" ]; then
            run rm -f "$f"
            good "Removed $(nice "$f")"
        fi
    done
    if [ -f "$CONFIG/fish/config.fish" ] && grep -q '^function fish_greeting_before_zeeshell\b' "$CONFIG/fish/config.fish"; then
        sed 's/^function fish_greeting_before_zeeshell\b\(.*\) # renamed by ZeeShell install.sh$/function fish_greeting\1/' "$CONFIG/fish/config.fish" | write_file "$CONFIG/fish/config.fish" || true
        good "Your fish greeting is back."
    fi
}

# The file explorer shows up in app launchers, and can be made the default
# file manager from Settings.
desktop_entry() {
    cat <<EOF
[Desktop Entry]
Type=Application
Name=ZeeShell Files
GenericName=File Manager
Comment=Browse your files with the ZeeShell file explorer
Exec=$BIN/zeeshell files %f
Icon=system-file-manager
Terminal=false
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
StartupWMClass=zeeshell-files
EOF
}

install_desktop_entry() {
    local apps="$DATA/applications"
    step "Adding ZeeShell Files to your apps"
    run mkdir -p "$apps"
    if desktop_entry | write_file "$apps/zeeshell-files.desktop"; then
        good "$(nice "$apps/zeeshell-files.desktop")"
    else
        good "$(nice "$apps/zeeshell-files.desktop") is already there."
    fi
}

# ---------------------------------------------------------------- Hyprland

lua_top_block() {
    cat <<'EOF'
-- >>> ZeeShell (added by install.sh; remove with install.sh --uninstall) >>>
-- Records what every bind does, for Settings -> Keybinds. Must run before any hl.bind.
pcall(dofile, (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/zeeshell/probe.lua")
-- <<< ZeeShell <<<
EOF
}

lua_bottom_block() {
    cat <<'EOF'
-- >>> ZeeShell (added by install.sh; remove with install.sh --uninstall) >>>
-- The shell's keybinds, the optional Steam workspace, and binds made in Settings.
do
	local dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/zeeshell/"
	for _, name in ipairs({ "binds.lua", "steam.lua", "generated.lua" }) do
		local f = io.open(dir .. name, "r")
		if f then
			f:close()
			local ok, err = pcall(dofile, dir .. name)
			if not ok then
				print("ZeeShell: " .. name .. ": " .. tostring(err))
			end
		end
	end
	pcall(function()
		zeeshell_binds.dump()
	end)
end
-- <<< ZeeShell <<<
EOF
}

conf_block() {
    cat <<EOF
# >>> ZeeShell (added by install.sh; remove with install.sh --uninstall) >>>
source = $HOOKS/zeeshell.conf
# <<< ZeeShell <<<
EOF
}

# Copy a file we own into the hooks folder, replacing an older copy.
put_managed() {
    if [ ! -f "$HOOKS/$1" ] || ! cmp -s "$SRC/hypr/$1" "$HOOKS/$1"; then
        run cp "$SRC/hypr/$1" "$HOOKS/$1"
    fi
}

# Copy a file the user owns: only when it is not there yet.
put_once() {
    if [ -f "$HOOKS/$1" ]; then
        info "Keeping your $(nice "$HOOKS/$1")"
    else
        run cp "$SRC/hypr/$1" "$HOOKS/$1"
        good "Default keybinds: $(nice "$HOOKS/$1")"
    fi
}

install_hyprland() {
    [ "$WITH_HYPR" = no ] && return 0
    step "Connecting to Hyprland"

    local kind=""
    if [ -f "$HYPR/hyprland.lua" ]; then
        kind=lua
    elif [ -f "$HYPR/hyprland.conf" ]; then
        kind=conf
    else
        warn "No Hyprland config found in $(nice "$HYPR"); skipping. Run this again once Hyprland is set up."
        return 0
    fi

    run mkdir -p "$HOOKS"

    if [ "$kind" = lua ]; then
        put_managed probe.lua
        put_managed steam.lua
        put_once binds.lua
        if { lua_top_block; echo; strip_blocks "$HYPR/hyprland.lua" "--"; echo; lua_bottom_block; } | write_file "$HYPR/hyprland.lua"; then
            good "Added ZeeShell's two blocks to $(nice "$HYPR/hyprland.lua")"
        else
            good "$(nice "$HYPR/hyprland.lua") already has ZeeShell's blocks."
        fi
    else
        put_once zeeshell.conf
        if { strip_blocks "$HYPR/hyprland.conf" "#"; echo; conf_block; } | write_file "$HYPR/hyprland.conf"; then
            good "Added a source line to $(nice "$HYPR/hyprland.conf")"
        else
            good "$(nice "$HYPR/hyprland.conf") already sources ZeeShell."
        fi
        warn "hyprland.conf setup: the keybind editor and the Steam workspace need Hyprland's Lua config."
    fi

    reload_hyprland
}

reload_hyprland() {
    [ "$RELOAD" = 1 ] || return 0
    [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 0
    command -v hyprctl >/dev/null 2>&1 || return 0
    if [ "$DRY" = 1 ]; then
        printf '  %swould run:%s hyprctl reload\n' "$DIM" "$OFF"
        return 0
    fi
    if hyprctl reload >/dev/null 2>&1; then
        local errors
        errors="$(hyprctl configerrors 2>/dev/null | sed '/^[[:space:]]*$/d' || true)"
        if [ -n "$errors" ]; then
            warn "Hyprland reloaded but reports config errors:"
            printf '%s\n' "$errors" | sed 's/^/      /'
        else
            good "Hyprland reloaded with no config errors."
        fi
    fi
}

# --------------------------------------------------------------- uninstall

# The shell writes a KDE colour scheme and a Vesktop theme while it runs.
# Take them away again, and hand KDE back the scheme it had before.
remove_app_themes() {
    local previous="" current="" f
    if [ -f "$CONFIG/zeeshell/config.json" ]; then
        previous="$(sed -n 's/.*"kdePrevious": *"\([^"]*\)".*/\1/p' "$CONFIG/zeeshell/config.json" | head -1)"
    fi
    if command -v kreadconfig6 >/dev/null 2>&1; then
        current="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
    fi
    case "$current" in
        ZeeShell*)
            if [ -n "$previous" ] && command -v plasma-apply-colorscheme >/dev/null 2>&1; then
                run plasma-apply-colorscheme "$previous"
                good "KDE apps are back on the \"$previous\" colour scheme."
            else
                warn "KDE apps still use ZeeShell's colours; pick another colour scheme in System Settings."
            fi
            ;;
    esac
    for f in "$DATA/color-schemes/ZeeShell.colors" "$DATA/color-schemes/ZeeShellAlt.colors" "$CONFIG/vesktop/themes/zeeshell.theme.css"; do
        if [ -e "$f" ]; then
            run rm -f "$f"
            good "Removed $(nice "$f")"
        fi
    done
}

uninstall() {
    step "Removing ZeeShell"

    if [ -L "$BIN/zeeshell" ]; then
        run rm -f "$BIN/zeeshell"
        good "Removed $(nice "$BIN/zeeshell")"
    fi

    if [ -L "$DEST" ]; then
        run rm -f "$DEST"
        good "Removed the link $(nice "$DEST") (the folder it pointed to is untouched)."
    elif [ -d "$DEST" ]; then
        if [ -f "$DEST/$MARKER" ] || [ "$FORCE" = 1 ]; then
            run rm -rf "$DEST"
            good "Removed $(nice "$DEST")"
        else
            warn "$(nice "$DEST") was not created by this installer; left alone (use --force to remove it)."
        fi
    fi

    if [ -f "$HYPR/hyprland.lua" ] && has_blocks "$HYPR/hyprland.lua" "--"; then
        strip_blocks "$HYPR/hyprland.lua" "--" | write_file "$HYPR/hyprland.lua" || true
        good "Removed ZeeShell's blocks from $(nice "$HYPR/hyprland.lua")"
    fi
    if [ -f "$HYPR/hyprland.conf" ] && has_blocks "$HYPR/hyprland.conf" "#"; then
        strip_blocks "$HYPR/hyprland.conf" "#" | write_file "$HYPR/hyprland.conf" || true
        good "Removed ZeeShell's source line from $(nice "$HYPR/hyprland.conf")"
    fi

    if [ -d "$HOOKS" ]; then
        local f
        for f in probe.lua steam.lua generated.lua flags.lua; do
            [ -e "$HOOKS/$f" ] && run rm -f "$HOOKS/$f"
        done
        if [ "$PURGE" = 1 ]; then
            run rm -rf "$HOOKS"
        elif [ -z "$(ls -A "$HOOKS" 2>/dev/null)" ]; then
            run rmdir "$HOOKS"
        else
            info "Kept your keybind file in $(nice "$HOOKS") (remove it with --purge)."
        fi
    fi

    remove_app_themes
    remove_terminal

    if [ -f "$DATA/applications/zeeshell-files.desktop" ]; then
        if [ "$(xdg-mime query default inode/directory 2>/dev/null || true)" = zeeshell-files.desktop ]; then
            local before=""
            [ -f "$CACHE/zeeshell/previous-file-manager" ] && before="$(cat "$CACHE/zeeshell/previous-file-manager")"
            if [ -n "$before" ]; then
                run xdg-mime default "$before" inode/directory
                good "Folders open with $before again."
            else
                warn "ZeeShell Files was your default file manager; choose another one in your system settings."
            fi
        fi
        run rm -f "$DATA/applications/zeeshell-files.desktop"
        good "Removed $(nice "$DATA/applications/zeeshell-files.desktop")"
    fi

    if [ "$PURGE" = 1 ]; then
        run rm -rf "$CONFIG/zeeshell" "$CACHE/zeeshell"
        good "Removed settings and cache."
    elif [ -d "$CONFIG/zeeshell" ]; then
        info "Kept your settings in $(nice "$CONFIG/zeeshell") (remove them with --purge)."
    fi

    reload_hyprland
    info "If the shell is still running, stop it with: qs kill -p <its folder>, or log out."
}

# -------------------------------------------------------------------- main

[ "$DRY" = 1 ] && printf '%sDry run: nothing will be changed.%s\n' "$BOLD" "$OFF"

if [ "$ACTION" = uninstall ]; then
    uninstall
    exit 0
fi

check_requirements
install_shell
install_desktop_entry
install_hyprland
install_terminal

if [ "$START" = 1 ] && [ "$DRY" = 0 ]; then
    step "Starting ZeeShell"
    if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
        warn "A Quickshell shell is already running. Stop it first so you do not get two bars."
    fi
    setsid -f "$BIN/zeeshell" >/dev/null 2>&1 || warn "Could not start it; run \`zeeshell\` yourself."
fi

step "Done"
info "Start it now:        zeeshell"
info "It starts by itself: at your next Hyprland login"
info "Open the drawer:     Super + Space      Settings: Super + ,"
info "Default keys live in $(nice "$HOOKS") and in Settings -> Keybinds."
info "Matching colours for Dolphin and Vesktop: Settings -> Appearance -> Other apps."
info "File explorer:       zeeshell files      (Super + E)"
info "Terminal greeter:    zeeshell fetch"
if pgrep -x waybar >/dev/null 2>&1; then
    warn "waybar is running. Remove it from your autostart so you do not end up with two bars."
fi
