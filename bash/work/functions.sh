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

alias control-center='unset XDG_CURRENT_DESKTOP; gnome-control-center &>/dev/null &'
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
HISTSIZE=-1
# HISTFILESIZE=

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
	xrandr --fb 1920x1080
}

screen_desktop3()
{
	xrandr --output DP-1 --mode 1920x1200 --pos 0x0 --output DP-4 --mode 1920x1080 --pos 1920x0 --output DP-3 --mode 1920x1200 --pos 3840x0
}

vlans_down ()
{
	for i in $(ip r | grep -oE "enp[^. ]+\..");
	do
		sudo ifdown $i;
	done
}
