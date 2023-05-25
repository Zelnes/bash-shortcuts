#!/bin/bash

MAX_LEN=10

playerctl() {
    ${HOME}/.config/i3/bin/playerctl.sh "$@"
}

trimWhitespaces() {
    sed -r 's/[[:blank:]]+/ /g'
}

#  metadata mpris:artUrl
# # file:///home/mgh/.mozilla/firefox/firefox-mpris/449139_281.png
# /home/mgh/.config/i3/bin/playerctl.sh metadata xesam:title
# # Best Brutal Dubstep Mix 2016 [2 HOUR LONG GAMING MUSIC]
# /home/mgh/.config/i3/bin/playerctl.sh metadata xesam:artist

current_artist="$(playerctl metadata xesam:artist | trimWhitespaces)"
current_song="$(playerctl metadata xesam:title | trimWhitespaces)"
current_icon="$(playerctl metadata mpris:artUrl)"

mkdir -p /tmp/player_metadata
touch /tmp/player_metadata/current_song

if [ ! -f /tmp/player_metadata/offset ]; then
    echo "0" > /tmp/player_metadata/offset
fi

if [ "$(cat /tmp/player_metadata/current_song)" != "$current_song" ]; then
    echo "$current_song" > /tmp/player_metadata/current_song
    notify-send -t 15000 -i "$current_icon" "$current_artist" "Title: $current_song"
    offset=0
else
    offset=$(cat /tmp/player_metadata/offset)
fi

if [ "$((offset + MAX_LEN))" -gt "${#current_song}" ]; then
    offset=0
fi
echo "$current_artist:${current_song:$offset:$MAX_LEN}"
echo "$((offset + 1))" > /tmp/player_metadata/offset

case "$(playerctl status)" in
    Playing) echo -e "#00FF00";;
    Paused) echo -e "#FFE100";;
    Stopped) echo -e "#FF0000";;
    *) echo "#523407";;
esac