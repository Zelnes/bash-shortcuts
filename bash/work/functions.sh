#!/bin/bash

# my_path=$(realpath $(dirname ${BASH_SOURCE[0]}))
# source ${my_path}/bash_functions.sh

PID_F="/tmp/pico_pid"

alias box_device='readlink -f /proc/$(cat ${PID_F})/fd/0'

send_command_box()
{
	[ -f ${PID_F} ] && ttyecho -n $(box_device) "$@"
}

reboot_box_cfe()
{
	send_command_box reboot
	sleep 5
	for i in {0..10}; do
		ttyecho -n $(box_device) " "
		sleep 0.5
	done
}

send_reboot_box()
{
	send_command_box r n 192.168.1.100 openwrt-broadcom-6836-vmlinux-initramfs-rd.elf  noramdisk 96836.dtb 0x04000000
}

alias control-center='XDG_CURRENT_DESKTOP=GNOME gnome-control-center &>/dev/null &'
# alias control-center='unset XDG_CURRENT_DESKTOP; gnome-control-center &>/dev/null &'
alias ssh-registry='ssh docker@192.168.100.238'
alias mtail-sdk='mtail -f make_log1.rej -w "==== My Marker MGH ===="'
alias connect_box='sudo ifconfig box0 {192.168.1.100,down,up}'
alias findn='find -name'
alias search-package='dpkg -S '

__do_in_sdk()
{
	(
		git_cd_n # go back to the higher git directory, hopefully it is sdk
		[ ! -f .current_board ] && {
			>&2 echo "No current board/target known in $(pwd)"
			exit 1
		}
		"$@"
	)
}

_make_verbose()
{
	local ret
	[ -f make_log1.rej ] && cp make_log1.rej make_log1.bak.rej
	dmake "$@" V=sc -j1 --trace >make_log1.rej
	ret=$?
	cp make_log1.rej make_log1.cpy.rej
	return $ret
}
make_verbose()
{
	__do_in_sdk _make_verbose "$@"
}


_sdk_docker_make()
{
	( git_cd_n && _docker_make "$@"; )
}

complete -F _sdk_docker_make make_verbose

make_single_package()
{
	[ ${1:0:1} = "-" ] || {
		dmake $@ || exit $?
		shift
	}
	dmake $@ package/install target/install package/index checksum
}

open-any()
{
	xdg-open $@ &>/dev/null &
}

alias t='set_static_title Test; cd ~/test'
alias sdk='set_static_title SDK; cd /home/mgh/dev/sdk'
alias sdk2='set_static_title "SDK 2"; cd /home/mgh/dev/sdk-2'
alias dsb_packages='set_static_title "DSB Packages"; cd /home/mgh/dev/sdk-feeds/dsb_packages/'
alias dock='set_static_title Docker; cd /home/mgh/dev/dockerfiles'

# Sets unlimited history size
export HISTSIZE=""
export HISTFILESIZE=-1
export FROMHISTFILE=~/bash_history/full_history
export HISTFILE=$(mktemp -p ~/bash_history/)

__save_history() {
	{
		diff "${FROMHISTFILE}" "${HISTFILE}" | sed -n 's/> //p' >>"${FROMHISTFILE}";
	} 2>/dev/null
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
# Set this function to be called when bash exits
trap __finish_trap EXIT
__reload_history

# Will launch the given command for the current board
__current_board_command()
{
	local cmd="$1"; shift
	local args="$@"
	(
		git_cd_n # go back to the higher git directory, hopefully it is sdk
		[ ! -f .current_board ] && {
			>&2 echo "No current board/target known in $(pwd)"
			exit 1
		}
		local target=$(cat .current_board)-$(cat .current_config)
		echo "Running : dmake ${target}${cmd} ${args}"
		dmake ${target}${cmd} "${args}"
	)
}

# Will launch the make menuconfig for the current target
menuconfig()
{
	__current_board_command "-menuconfig"
}

# Will compile the current target
compile()
{
	__current_board_command "" -j10 "$@"
}

# Compile anything
compilea()
{
	__current_board_command "$@"
}

flash_image()
{
	local img="$1" secure

	[ -f "${img}" ] || {
		[[ "${img}" =~ ^/tftpboot ]] || img="/tftpboot/${img}"
		[ -f "${img}" ] || {
			1>&2 echo "No image ${img} found"
			return 1
		}
	}
	echo ${img}
	if [[ "${img}" =~ .*secure ]]; then
		>&2 echo "Attention : the image '${img}' contains 'secure' in its name"
		>&2 echo "Are you sure you want to flash it ? (y/n)"
		read secure
		[ "${secure}" != "y" ] && {
			echo "Aborting"
			return 0
		}
	fi
	curl -o /dev/null -F"filename=@${img}" http://192.168.1.1/upload.cgi
}

screen_add_right() {
	xrandr --output DP-1 --mode 1920x1200 --pos 1920x0
}

screen_remove_right() {
	xrandr --output eDP-1 --mode 1920x1080 --pos 0x0
}

screen_desktop3() {
	# xrandr --output DP-1 --mode 1920x1200 --pos 0x0 --output DP-4 --mode 1920x1080 --pos 1920x0 --output DP-3 --mode 1920x1200 --pos 3840x0
	xrandr --output DP-3 --mode 3840x1600 --pos 1920x0 --output eDP-1 --mode 1920x1080 --pos 0x0 --output DP-2 --mode 1920x1200 --pos 5760x0 --rotate left
}

screen_salle_e1_004_p12() {
	xrandr --output DP-2 --mode 1920x1080 --pos 0x0 --output eDP-1 --mode 1920x1080 --pos 1920x0
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
