#!/bin/sh
set -eu

ip -4 addr replace 10.0.0.10/16 dev lan0
ip route replace default via 10.0.10.254 dev lan0
base=http://203.72.59.10
cookie_jar=$(mktemp)
trap 'rm -f "$cookie_jar"' EXIT
trap 'exit 0' INT TERM

request() {
    curl --noproxy '*' -fsS --max-time 8 --cookie "$cookie_jar" --cookie-jar "$cookie_jar" "$@"
}

visit() {
    request "$base/" | grep -q '/admin/login.php' &&
    request "$base/admin/login.php" | grep -q 'name="password"' &&
    request --location --data-urlencode "username=$LAB_WEB_USER" \
        --data-urlencode "password=$LAB_WEB_PASSWORD" "$base/admin/login.php" |
        grep -q 'id="actions">0</output>' &&
    request --data 'action=increment' "$base/admin/panel.php" |
        grep -q 'id="actions">1</output>' &&
    request --location --data 'action=logout' "$base/admin/panel.php" |
        grep -q 'name="password"'
}

while :; do
    : > "$cookie_jar"
    if visit; then
        printf '%s index -> login -> admin action -> logout OK\n' "$(date -Is)"
    else
        printf '%s HTTP cycle failed. Retrying in %ss.\n' "$(date -Is)" "$LAB_INTERVAL" >&2
    fi
    sleep "$LAB_INTERVAL"
done
