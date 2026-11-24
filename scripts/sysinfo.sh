#!/usr/bin/env bash
# Streams one JSON line of system stats every interval. Pure /proc and /sys
# reads, so it costs next to nothing to keep running.
interval=${1:-2}

cpu_temp=""
for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name" 2>/dev/null)" in
        k10temp|coretemp|zenpower|cpu_thermal) cpu_temp="$h/temp1_input"; break ;;
    esac
done

# Use the GPU with the most VRAM (the discrete one on hybrid systems).
gpu=""; best=0
for c in /sys/class/drm/card?/device; do
    [ -r "$c/gpu_busy_percent" ] || continue
    v=$(cat "$c/mem_info_vram_total" 2>/dev/null || echo 1)
    if [ "$v" -gt "$best" ]; then best=$v; gpu=$c; fi
done
gpu_temp=""
if [ -n "$gpu" ]; then
    for t in "$gpu"/hwmon/hwmon*/temp1_input; do [ -r "$t" ] && gpu_temp=$t && break; done
fi

read_cpu() { read -r _ a b c d e f g h _ < /proc/stat; idle=$((d + e)); total=$((a + b + c + d + e + f + g + h)); }
read_net() {
    iface=$(ip route show default 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
    rx=0; tx=0
    if [ -n "$iface" ] && [ -r "/sys/class/net/$iface/statistics/rx_bytes" ]; then
        rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes"); tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
    fi
}

read_cpu; pidle=$idle; ptotal=$total
read_net; prx=$rx; ptx=$tx; piface=$iface
first=1
while :; do
    if [ "$first" = 1 ]; then sleep 0.4; step=0.4; first=0; else sleep "$interval"; step=$interval; fi

    read_cpu
    dt=$((total - ptotal)); di=$((idle - pidle)); cpu=0
    [ "$dt" -gt 0 ] && cpu=$(((1000 * (dt - di) / dt + 5) / 10))
    pidle=$idle; ptotal=$total

    mt=0; ma=0
    while read -r k v _; do
        case $k in MemTotal:) mt=$v ;; MemAvailable:) ma=$v ;; esac
    done < /proc/meminfo

    ct=0; [ -n "$cpu_temp" ] && ct=$(($(cat "$cpu_temp" 2>/dev/null || echo 0) / 1000))
    gu=-1; gt=0; vu=0; vt=0
    if [ -n "$gpu" ]; then
        gu=$(cat "$gpu/gpu_busy_percent" 2>/dev/null || echo 0)
        [ -n "$gpu_temp" ] && gt=$(($(cat "$gpu_temp" 2>/dev/null || echo 0) / 1000))
        vu=$(cat "$gpu/mem_info_vram_used" 2>/dev/null || echo 0)
        vt=$(cat "$gpu/mem_info_vram_total" 2>/dev/null || echo 0)
    fi

    read_net
    rxs=0; txs=0
    if [ "$iface" = "$piface" ]; then
        rxs=$(awk -v a="$rx" -v b="$prx" -v s="$step" 'BEGIN { printf "%d", (a - b) / s }')
        txs=$(awk -v a="$tx" -v b="$ptx" -v s="$step" 'BEGIN { printf "%d", (a - b) / s }')
    fi
    prx=$rx; ptx=$tx; piface=$iface

    read -r du dsz < <(df -B1 --output=used,size / 2>/dev/null | tail -1)
    read -r up _ < /proc/uptime

    printf '{"cpu":%d,"memUsed":%d,"memTotal":%d,"cpuTemp":%d,"gpu":%d,"gpuTemp":%d,"vramUsed":%s,"vramTotal":%s,"rx":%d,"tx":%d,"diskUsed":%s,"diskTotal":%s,"uptime":%d,"iface":"%s"}\n' \
        "$cpu" "$((mt - ma))" "$mt" "$ct" "$gu" "$gt" "${vu:-0}" "${vt:-0}" "$rxs" "$txs" "${du:-0}" "${dsz:-1}" "${up%.*}" "$iface"
done
