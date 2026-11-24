#!/usr/bin/env bash
# ZeeShell's terminal greeter: the mark, and what this machine is.
# Run it as `zeeshell fetch`. Set ZEESHELL_NO_FETCH=1 to silence it.
#
# Things that never change between boots (CPU, GPU, OS) are cached for a day,
# so this stays fast enough to run every time a terminal opens.

[ -n "${ZEESHELL_NO_FETCH:-}" ] && exit 0
[ -t 1 ] || exit 0

cache="${XDG_CACHE_HOME:-$HOME/.cache}/zeeshell"
mkdir -p "$cache" 2>/dev/null

# Colours follow the shell; these are the defaults when it has not run yet.
accent=8eb4f6 ink=111d32 text=eceff4 dim=b4bac6 mute=79818f
[ -r "$cache/palette" ] && . "$cache/palette"

rgb() { printf '%d;%d;%d' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
A="$(rgb "$accent")" I="$(rgb "$ink")" T="$(rgb "$text")" D="$(rgb "$dim")" M="$(rgb "$mute")"
fg() { printf '\e[38;2;%sm' "$1"; }
reset=$'\e[0m' bold=$'\e[1m'

# ---- facts that hold still: cached ---------------------------------------
specs="$cache/specs"
if [ ! -s "$specs" ] || [ -n "$(find "$specs" -mmin +1440 2>/dev/null)" ] || ! grep -q "^kernel=$(uname -r)\$" "$specs" 2>/dev/null; then
    os="Linux"
    [ -r /etc/os-release ] && os="$(. /etc/os-release; printf '%s' "${PRETTY_NAME:-$NAME}")"
    cpu="$(awk -F': ' '/model name/ { print $2; exit }' /proc/cpuinfo 2>/dev/null | sed -e 's/([^)]*)//g' -e 's/ [0-9]*-Core Processor//' -e 's/ CPU.*//' -e 's/  */ /g')"
    threads="$(nproc 2>/dev/null)"
    # Ask the graphics driver first: it knows the exact model. The PCI name is
    # only a fallback, because one PCI id often covers several cards
    # ("RX 9070/9070 XT/9070 GRE") and guessing between them would be wrong.
    gpu=""
    if command -v vulkaninfo >/dev/null 2>&1; then
        # The discrete card if there is one, otherwise the first real GPU.
        gpu="$(vulkaninfo --summary 2>/dev/null | awk -F'= ' '
            /deviceType/ { type = $2 }
            /deviceName/ {
                name = $2; sub(/ \(.*/, "", name)
                if (type ~ /DISCRETE/) { print name; done = 1; exit }
                if (first == "" && type !~ /CPU/) first = name
            }
            END { if (!done && first != "") print first }')"
    fi
    if [ -z "$gpu" ] && command -v glxinfo >/dev/null 2>&1; then
        gpu="$(glxinfo -B 2>/dev/null | sed -n 's/^OpenGL renderer string: //p' | sed 's/ (.*//' | head -1)"
    fi
    if [ -z "$gpu" ] && command -v lspci >/dev/null 2>&1; then
        gpu="$(lspci -mm 2>/dev/null | awk -F'"' '/VGA|3D|Display/ { print $6; exit }' | sed -e 's/.*\[\(.*\)\].*/\1/')"
    fi
    wm=""
    command -v hyprctl >/dev/null 2>&1 && wm="$(hyprctl version 2>/dev/null | awk '/^Tag:/ { sub(/,.*/, "", $2); sub(/^v/, "", $2); print "Hyprland " $2; exit }')"
    {
        printf 'kernel=%s\n' "$(uname -r)"
        printf 'os=%q\n' "$os"
        printf 'cpu=%q\n' "$cpu${threads:+ ($threads)}"
        printf 'gpu=%q\n' "$gpu"
        printf 'wm=%q\n' "${wm:-Hyprland}"
        printf 'host=%q\n' "$(cat /etc/hostname 2>/dev/null || uname -n)"
    } > "$specs" 2>/dev/null
fi
kernel="" os="" cpu="" gpu="" wm="" host=""
[ -r "$specs" ] && . "$specs"

# ---- facts that move: read now ---------------------------------------------
mem="$(awk '/MemTotal/ { t = $2 } /MemAvailable/ { a = $2 } END { printf "%.1f / %.1f GiB", (t - a) / 1048576, t / 1048576 }' /proc/meminfo 2>/dev/null)"
disk="$(df -B1 --output=used,size / 2>/dev/null | awk 'NR == 2 { u = $1; s = $2; unit = "GiB"; d = 1073741824; if (s > 1099511627776) { unit = "TiB"; d = 1099511627776 } printf "%.1f / %.1f %s", u / d, s / d, unit }')"
up="$(awk '{ s = int($1); d = int(s / 86400); h = int(s % 86400 / 3600); m = int(s % 3600 / 60); if (d) printf "%dd %dh", d, h; else if (h) printf "%dh %dm", h, m; else printf "%dm", m }' /proc/uptime 2>/dev/null)"

# ---- the mark, drawn with half blocks ---------------------------------------
# A 20 x 20 grid: a rounded tile with a Z on it. Each text row shows two grid
# rows, using the upper-half block with separate foreground and background.
N=20
P=0
pixel() { # sets P: 0 outside the tile, 1 tile, 2 the Z. (No subshells: this runs 400 times.)
    local x=$1 y=$2 r=5 cx=$1 cy=$2 mid
    ((x < r)) && cx=$r
    ((x > N - 1 - r)) && cx=$((N - 1 - r))
    ((y < r)) && cy=$r
    ((y > N - 1 - r)) && cy=$((N - 1 - r))
    if (((x - cx) * (x - cx) + (y - cy) * (y - cy) > r * r)); then P=0; return; fi
    if ((x >= 5 && x <= 14 && ((y >= 5 && y <= 6) || (y >= 13 && y <= 14)))); then P=2; return; fi
    if ((y >= 7 && y <= 12)); then
        mid=$((14 - (y - 6) * 9 / 7))
        if ((x >= mid - 1 && x <= mid + 1)); then P=2; return; fi
    fi
    P=1
}
shade=("" "$A" "$I")

logo=()
for ((row = 0; row < N; row += 2)); do
    line=""
    for ((x = 0; x < N; x++)); do
        pixel "$x" "$row"; top=$P
        pixel "$x" $((row + 1)); bot=$P
        if ((top == 0 && bot == 0)); then line+="${reset} "
        elif ((top == 0)); then line+="${reset}"$'\e[38;2;'"${shade[bot]}m▄"
        elif ((bot == 0)); then line+="${reset}"$'\e[38;2;'"${shade[top]}m▀"
        else line+=$'\e[38;2;'"${shade[top]}"$'m\e[48;2;'"${shade[bot]}m▀"
        fi
    done
    logo+=("$line${reset}")
done

# ---- the facts, beside it ----------------------------------------------------
row() { printf '%s%-8s%s %s%s' "$(fg "$A")$bold" "$1" "$reset" "$(fg "$T")" "$2$reset"; }
info=(
    "$(fg "$A")$bold${USER:-user}$reset$(fg "$M")@$reset$(fg "$T")$bold$host$reset"
    "$(fg "$M")$(printf '%*s' "$((${#USER} + ${#host} + 1))" '' | tr ' ' '-')$reset"
    "$(row OS "$os")"
    "$(row Kernel "$kernel")"
    "$(row Shell "ZeeShell · $wm")"
    "$(row CPU "$cpu")"
)
[ -n "$gpu" ] && info+=("$(row GPU "$gpu")")
info+=(
    "$(row Memory "$mem")"
    "$(row Disk "$disk")"
    "$(row Uptime "$up")"
)

echo
lines=${#logo[@]}
[ ${#info[@]} -gt "$lines" ] && lines=${#info[@]}
blank="$(printf '%*s' "$N" '')"
for ((i = 0; i < lines; i++)); do
    printf '  %s   %s\n' "${logo[i]:-$blank}" "${info[i]:-}"
done
echo
