#!/bin/bash

. "$(realpath $(dirname ${BASH_SOURCE[0]}))/pulse_routines"

toggle_connection() {
	toggle_bluez
}

set_profile() {
	local profile="$1"
	local real_prof="$(list_profiles_card_bluez "$profile")"
	local curr_prof="$(list_current_profile_card_bluez)"
	[ -z "$real_prof" ] && return
	# [ "$real_prof" != "$curr_prof" ] &&
	pacmd set-card-profile $(__pa_get_bluez_num cards) "$real_prof"
	client_id_to_sink any $(__pa_get_bluez_num sinks)
	logger "Switched Jabra headset to HFP profile"

}

vpn_wg() {
	sudo wg-quick "$1" dsb0
}

main() {
	"$@" 2>/dev/null || echo "No such command '$@'"
}

main "$@"