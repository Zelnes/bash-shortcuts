#!/bin/bash

export HISTDIR="$HOME/bash_history"

# Sets unlimited history size
export HISTSIZE=""
export HISTFILESIZE=-1
export FROMHISTFILE="$HISTDIR/full_history"
export HISTTEMPLATE="hist_template.XXXXXXXX"
export HISTPURGE="$(mktemp -du)"

HISTLOCK="${HISTDIR}/HISTLOCK"

purge_history_dir() {
	(
		set -e
		clean_history_dir
		mkdir -p "$HISTPURGE"
		send_command_to_all_terminal cp '$HISTFILE' "$HISTPURGE"
		rm $(__history_locate_templates)
		mv "$HISTPURGE"/* "$HISTDIR"
	)
	rm -rf "$HISTPURGE"
}

clean_history() {
	local from="$1";
	local tmp="${from}2"
	{
		flock 42
		awk '{a[$0]=1} END{for(i in a) print i}' "$@" | sort >"${tmp}"
		# rm "$@" ?
		mv "${tmp}" "${from}"
	} 42>"$HISTLOCK"
}

__save_history() {
	{
		# Flush current history in the file
		history -w
		clean_history "${FROMHISTFILE}" "${HISTFILE}"
	}
}

__reload_history() {
	__save_history
	cp "${FROMHISTFILE}" "${HISTFILE}"
}

__finish_trap() {
	local temp="${HISTFILE}"
	__save_history
	export HISTFILE="${FROMHISTFILE}"
	rm "${temp}"
}

__history_locate_templates() {
	find "${HISTDIR}" -name "${HISTTEMPLATE//.X*/}.*"
}

# This command cleans the history directory
clean_history_dir() {
	clean_history "${FROMHISTFILE}" $(__history_locate_templates)
}

__init_history() {
	mkdir -p "${HISTDIR}"
	touch "${FROMHISTFILE}"

	if [ "$HISTFILE" = "$HOME/.bash_history" ] || [ -z "$HISTFILE" ]; then
		HISTFILE=$(mktemp -p "$HISTDIR" "$HISTTEMPLATE")
	fi
	export HISTFILE

	# Set this function to be called when bash exits
	trap __finish_trap EXIT
	__reload_history
}
__init_history

screen_add_right() {
	xrandr --output DP-1 --mode 1920x1200 --pos 1920x0
}

screen_remove_right() {
	xrandr --output eDP-1 --mode 1920x1080 --pos 0x0
}

screen_desktop3() {
	# xrandr --output DP-1 --mode 1920x1200 --pos 0x0 --output DP-4 --mode 1920x1080 --pos 1920x0 --output DP-3 --mode 1920x1200 --pos 3840x0
	xrandr --output DP-3  --mode 3840x1600 --pos 1920x0 \
	       --output eDP-1 --mode 1920x1080 --pos 0x0 \
	       --output DP-2  --mode 1920x1200 --pos 5760x0 --rotate left
}

screen_only_big() {
	local location="${1:-left}"
	xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 \
	       --output DP-2  --mode 3840x1600 --${location}-of eDP-1
}

screen_salle_e1_004_p12() {
	local location="${1:-left}"
	xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 \
	       --output DP-2  --mode ${RES:-1920x1080} --${location}-of eDP-1
}

vlans_down ()
{
	for i in $(ip r | grep -oE "enp[^. ]+\..");
	do
		sudo ifdown $i;
	done
}

# $1 : {up/down}
vlans_conf() {
	local state="$1" i
	case "$state" in
		up|down)
			for i in $(ip link | awk '/^[0-9]+:/ && /enp0s31f6\./ { sub(/@.*/, "", $2); print $2}'); do
				sudo ip link set $i $state
			done
			;;
		*)
			echo "Wrong state; must be {up,down}"
			return 1
			;;
	esac
}

# $1 : Network SSID
# Get list : wpa_cli list_network -i wlp4s0 | awk -F'\t' 'NR > 1{print $2}' | sort -u
# TODO : mettre une fonction de complétion
wpa_qrcode() {
	local network="$1"
	awk -v net="$network" -F'[="[:blank:]]+' '
		BEGIN {
			RS = "network={";
		}
		{
			for (i = 1; i <= NF; ++i)
				if ($i == "ssid") {
					if ($(++i) != net)
						next;
					else
						continue;
				}
				if ($i == "psk") {
					printf("%s", $(i+1));
					exit;
				}
		}' /etc/wpa_supplicant/wpa_supplicant.conf | qrencode -t utf8
}

enable_ethernet() {
	local wifi=wlp4s0
	sudo -- sh -c "
	dhclient -r ${wifi}
	wpa_cli -i ${wifi} disconnect
	wg-quick down dsb0
	dhclient -v internet
	ethtool -r enp0s31f6
	"
}

enable_wifi() {
	local wifi=wlp4s0
	local network="$1"
	local wpa="wpa_cli -i ${wifi}"
	sudo -- sh -c "
	ID=$(${wpa} list_network | sed -n "s/\t${network}\t.*//p")
	[ -z \"\$ID\" ] && exit 1
	dhclient -r internet
	${wpa} select_network \$ID
	dhclient -v ${wifi}
	wg-quick up dsb0
	"
}

_wifi_known() {
	local cur opts cmd toot
	local wpa="wpa_cli -i wlp4s0"

	cur="${COMP_WORDS[COMP_CWORD]}"
	cur=${cur//\/\\}
	# cmd="${COMP_WORDS[*]}"
	# cmd=${cmd% *}
	# case "$(basename "${COMP_WORDS[0]}")" in
	# opts=$()
	# 	"build-host.sh") [ ${COMP_CWORD} -eq 1 ] && opts+=" --update" ;;
	# esac
	toot="$(${wpa} list_network | awk -F'\t' '$2 ~ /^'$cur'/ {print $2}')"
	# toot="$(${wpa} list_network | sed -r '1d; s/^[^\t]+\t//; s/(\t[^\t]*){2}$//; s/[[:blank:]]/\\&/g')"
	local IFS=$'\n'
	# COMPREPLY=( $(compgen -W "$toot" -- "$cur") )
	COMPREPLY=( $(printf "%q\n" $toot))
}
complete -F _wifi_known enable_wifi
