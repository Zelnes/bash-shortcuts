#!/bin/bash

vpn_openvpn_up() {
    pkexec /usr/sbin/service openvpn@reseau_train start
}

vpn_openvpn_down() {
    pkexec /usr/sbin/service openvpn@reseau_train stop
}

vpn_cisco_up() {
    local group="GROUP"
    local user_name="name"
    local url="url.net"

    printf '%s\n%s\n%s\n' \
        "$group" \
        "$user_name" \
        "$(pass show path/to/password)" \
        | /opt/cisco/anyconnect/bin/vpn -s connect "$url"
}

vpn_cisco_down() {
    /opt/cisco/anyconnect/bin/vpn disconnect
}

main() {
    "$@" 2>/dev/null || echo "No such command '$*'"
}

main "$@"