#!/bin/sh
set -eu

ip -4 addr replace 203.72.59.10/24 dev wan0
ip route replace default via 203.72.59.254 dev wan0
set +u
. /etc/apache2/envvars
set -u
exec /usr/sbin/apache2 -D FOREGROUND
