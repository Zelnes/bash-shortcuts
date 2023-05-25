#!/bin/bash

currentProxy() {
    local proxy="$(gsettings get org.gnome.system.proxy.http host | sed "s,',,g;")"

    if [ -n "$proxy" ]; then
        echo "Proxy : $proxy"
        echo -e "#00FF00"
    else
        echo "Proxy : Off"
        echo -e "#FF0000"
    fi
}

main() {
    local cmd="$1"

    if [ -z "$cmd" ]; then
        currentProxy
    else
        echo "$cmd unkwown"
    fi
}

main "$@"
