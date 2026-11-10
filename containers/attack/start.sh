#!/bin/sh
set -eu

ip -4 addr replace 10.0.0.20/16 dev lan0
ip route replace default via 10.0.10.254 dev lan0
printf 'student:%s\n' "$LAB_ATTACK_PASSWORD" | chpasswd
install -d -m 0755 /run/sshd /run/dbus
case "${LAB_VNC_PASSWORD:-}" in
    ????????) ;;
    *) echo "LAB_VNC_PASSWORD must contain 8 ASCII letters or digits" >&2; exit 1 ;;
esac
case "$LAB_VNC_PASSWORD" in
    *[!0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz]*)
        echo "LAB_VNC_PASSWORD must contain 8 ASCII letters or digits" >&2; exit 1 ;;
esac
install -d -m 0700 -o student -g student /run/arp-lab-vnc
install -m 0600 -o student -g student /dev/null /run/arp-lab-vnc/passwd
printf '%s\n' "$LAB_VNC_PASSWORD" | tigervncpasswd -f > /run/arp-lab-vnc/passwd
unset LAB_VNC_PASSWORD

ssh-keygen -A
exec /usr/bin/supervisord -c /etc/lab-supervisord.conf
