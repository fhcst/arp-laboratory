#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

compose() {
    docker compose -p "${LAB_TEST_PROJECT:-arp-lab-smoke}" "$@"
}

cleanup() {
    status=$?
    trap - EXIT
    compose logs --no-color --tail 30
    compose down
    exit "$status"
}
trap cleanup EXIT

compose up -d --wait --wait-timeout 120
compose exec -T g01-attack python3 -c 'import scapy; print(scapy.__version__)'
compose exec -T g01-attack firefox --version
compose exec -T g01-attack runuser -u student -- code --version
curl --fail --retry 5 --retry-delay 1 --retry-connrefused \
    "http://127.0.0.1:${LAB_NOVNC_PORT_G01:-6080}/vnc.html" >/dev/null

for attempt in {1..30}; do
    if compose logs --tail 5 g01-victim | grep -q 'logout OK'; then
        break
    fi
    sleep 1
done
compose logs --tail 5 g01-victim | grep -q 'logout OK'

router_id=$(compose ps -q g01-router)
started=$(docker inspect --format '{{.State.StartedAt}}' "$router_id")
mac=$(compose exec -T g01-router cat /sys/class/net/lan0/address)
rules=$(compose exec -T g01-router nft --stateless list ruleset)
old_file=$(compose exec -T g01-router sh -c 'ls /captures/lan.*.pcap | sort | tail -n 1')
compose kill -s SIGUSR1 g01-router

new_file=$old_file
for attempt in {1..30}; do
    new_file=$(compose exec -T g01-router sh -c 'ls /captures/lan.*.pcap | sort | tail -n 1')
    if [ "$new_file" != "$old_file" ]; then
        break
    fi
    sleep 1
done
test "$new_file" != "$old_file"
test "$started" = "$(docker inspect --format '{{.State.StartedAt}}' "$router_id")"
test "$mac" = "$(compose exec -T g01-router cat /sys/class/net/lan0/address)"
test "$rules" = "$(compose exec -T g01-router nft --stateless list ruleset)"

filter='ip.src == 10.0.0.10 && ip.dst == 203.72.59.10 && http.request.method == "POST" && http.request.uri == "/admin/login.php" && urlencoded-form.key == "username" && urlencoded-form.key == "password"'
for attempt in {1..30}; do
    matches=$(compose exec -T g01-router tshark -r "$new_file" -Y "$filter" -T fields -e frame.number 2>/dev/null || true)
    if [ -n "$matches" ]; then
        break
    fi
    sleep 1
done
test -n "$matches"

# Graceful stop must leave both host-mounted files readable.
compose stop g01-router
test -s "captures/g01/${old_file##*/}"
test -s "captures/g01/${new_file##*/}"
docker run --rm --network none \
    --mount "type=bind,source=$PWD/captures/g01/${new_file##*/},target=/test.pcap,readonly" \
    --entrypoint tshark \
    "${LAB_IMAGE_PREFIX:-ghcr.io/fhcst/arp-laboratory}-router:${LAB_IMAGE_TAG:-latest}" \
    -r /test.pcap -Y "$filter" -T fields -e frame.number | grep -q '[0-9]'

echo "HTTP cycle, desktop endpoint, capture rotation and host PCAP verified."
