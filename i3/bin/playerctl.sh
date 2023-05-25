#!/bin/bash

# Ce script est un wrapper de playerctl.
# Il a pour but d'essayer de gérer Teams et les autres applications qui font du son

getTeamsPlayerId() {
    playerctl --list-all | while read player; do
        if isInstanceOfTeams "$player"; then
            echo "$player"
            return
        fi
    done
}

isInstanceOfTeams() {
    local pid="${1//*instance/}"

    grep -q "^/usr/share/teams/teams" "/proc/$pid/cmdline"
}

# Le script qui monitor teams écrit son status dans le fichier /tmp/teams_state
# Et le seul moment où il n'est pas en appel est quand la valeur IDLE est présente
isTeamsIDLE() {
    grep -q IDLE /tmp/teams_state
}


main() {
    # On va ignorer Teams s'il est en appel, sinon on ne fait rien de plus que ce qui est demandé
    local teams="$(getTeamsPlayerId)"

    if isTeamsIDLE; then
        set -- "$@" "--ignore-player" "$teams"
    fi

    command playerctl "$@"
}

main "$@"