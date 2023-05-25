#!/bin/bash

ssh_tunnels() {
    local host listHosts
    local connected=""

    if [ "${NO_TUNNEL_REBOND_PS1}" = "y" ]; then
        return 0
    fi

    listHosts="$(grep -P "^Host ([^*]+)$" "$HOME/.ssh/config" | sed 's/Host //')"

    for host in $listHosts; do
        if ssh -q -O check "$host" &>/dev/null; then
            connected="$host:$connected"
        fi
    done

    if [ -n "$connected" ]; then
        echo -e "SSH Tunnel ${connected%:}"
        echo -e "#00FF00"
    else
        echo "SSH Tunnel"
        echo -e "#FF0000"
    fi
}

ssh_tunnels