#!/bin/sh
set -eu

unset DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER
XDG_RUNTIME_DIR=$(mktemp -d)
export XDG_RUNTIME_DIR
trap 'rm -rf -- "$XDG_RUNTIME_DIR"' EXIT
dbus-run-session -- startxfce4
