#!/bin/bash
set -eu

ip -4 addr replace 10.0.0.30/16 dev lan0
management_ip=$(ip -4 -o addr show dev mgmt0 | awk '{split($4, ip, "/"); print ip[1]; exit}')
exec setpriv --bounding-set=-all --no-new-privs /bin/bash -ec '
    socat "TCP-LISTEN:2222,bind=$1,reuseaddr,fork" TCP:10.0.0.20:22 &
    socat "TCP-LISTEN:13389,bind=$1,reuseaddr,fork" TCP:10.0.0.20:3389 &
    socat "TCP-LISTEN:15901,bind=$1,reuseaddr,fork" TCP:10.0.0.20:5901 &
    socat "TCP-LISTEN:6080,bind=$1,reuseaddr,fork" TCP:10.0.0.20:6080 &
    wait -n
' -- "$management_ip"
