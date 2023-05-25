#!/bin/bash

# Ce script ne rend pas la main, et serait à sa place au lancement de Teams
# mais comme je le redémarre régulièrement, autant le mettre au démarrage d'i3

TEAMS_STORAGE="${HOME}/.config/Microsoft/Microsoft Teams/storage.json"

printCurrentStatus() {
    local status="" color
    local current_status current_state

    current_status="$(jq -r '.activityEvents.events | last' < "$TEAMS_STORAGE")"
    current_state="$(jq -r '.appStates.states' < "$TEAMS_STORAGE" | sed 's/.*,//')"

    case "${current_state}${current_status}" in
        *incoming_call*)
            status="Incoming Call"
            color="#BA7238";;
        *InCall*|*call_accept*)
            status="In call"
            color="#552A8C";;
        *CallEnded*|*calling_call_disconnected*)
            status="IDLE"
            color="#FFFFFF";;
    esac

    if [ -n "$status" ]; then
        {
            echo "Teams : $status"
            echo "$color"
        } >/tmp/teams_state
    fi
}

# Au démarrage, on ne va pas attendre une modification pour dire dans quel état se trouve Teams
printCurrentStatus

inotifywait -m -e modify "$TEAMS_STORAGE" | while read _dummy; do
    printCurrentStatus
done
