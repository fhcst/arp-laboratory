#!/bin/sh
set -eu

ip -4 addr replace 10.0.10.254/16 dev lan0
ip -4 addr replace 203.72.59.254/24 dev wan0
nft -f /lab/forward.nft

capture_path() {
    printf '/captures/lan.%s.pcap\n' "$(date -u +%Y%m%dT%H%M%SZ)"
}

capture_pid=
rotate=false
stopping=false

signal_capture() {
    if [ -n "$capture_pid" ]; then
        kill -TERM "$capture_pid" 2>/dev/null || true
    fi
}

trap 'stopping=true; signal_capture' INT TERM
trap 'rotate=true; signal_capture' USR1

while [ "$stopping" = false ]; do
    rotate=false
    capture=$(capture_path)
    while [ -e "$capture" ] && [ "$stopping" = false ]; do
        sleep 1
        capture=$(capture_path)
    done
    [ "$stopping" = false ] || break

    echo "Recording ARP and HTTP on lan0 to $capture"
    tcpdump -i lan0 -nn -s 0 -U -Z root -w "$capture" \
        'arp or (host 203.72.59.10 and tcp port 80)' &
    capture_pid=$!

    # A signal may arrive between launching tcpdump and saving its PID.
    if [ "$rotate" = true ] || [ "$stopping" = true ]; then
        signal_capture
    fi

    status=0
    wait "$capture_pid" || status=$?
    if [ "$rotate" = false ] && [ "$stopping" = false ]; then
        exit "$status"
    fi
    # A trapped signal interrupts wait. Reap tcpdump before starting a new file.
    while kill -0 "$capture_pid" 2>/dev/null; do
        wait "$capture_pid" || true
    done
    capture_pid=
done
