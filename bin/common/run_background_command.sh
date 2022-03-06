#!/bin/bash

print_time() {
	local counter=0
	local args="$*"
	# Restore cursor and move to new line when terminated
	trap 'tput cnorm; echo' EXIT
	trap 'exit 127' HUP INT TERM

	printf "Running '$args' :"
	# Make text cursor invisible
	tput civis
	# Save cursor position
	tput sc
	while true; do
		for char in '-' '\' '|' '/'; do
			# Back to saved position
			tput rc
			printf "%s %d seconds" "$char" "$((counter/4))"
			sleep 0.25
			counter=$((counter+1))
		done
	done
}

main() {
	local pidfile=$(mktemp)
	local output=$(mktemp)

	echo "Running $* &>$output"
	# Launche printer in background
	(print_time "$@" & echo $! >&3) 3>"$pidfile"

	time { "$@" &>"$output"; }
	kill "$(cat "$pidfile")"
	# restore cursor to normal
	tput cnorm

	rm -f "$pidfile"
}

main "$@"