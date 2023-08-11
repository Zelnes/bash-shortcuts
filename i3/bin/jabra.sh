#!/bin/bash

DEVICE_NAME="Jabra Elite 85h"

getDeviceMac() {
    bluetoothctl info | awk -v name="$DEVICE_NAME" 'BEGIN{RS="^Device";} $0 ~ "Name: " name {print $1}'
}

displayDeviceConnected() {
    bluetoothctl info "$(getDeviceMac)" | awk '/Connected/{print $NF}'
}

actionDevice() {
    bluetoothctl "$1" "$(getDeviceMac)"
}

case "$1" in
    "") echo "Jabra: $(displayDeviceConnected)";;
    connect|disconnect) actionDevice "$1";;
    *) echo "unknown command";;
esac
