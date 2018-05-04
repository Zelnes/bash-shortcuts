#!/bin/bash

# my_path=$(realpath $(dirname ${BASH_SOURCE[0]}))
# source ${my_path}/bash_functions.sh

send_command_box()
{
	connect_box
	local PID_F="/tmp/pico_pid"
	if [[ -f ${PID_F} ]]; then
		ttyecho -n $(readlink -f /proc/$(cat ${PID_F})/fd/0) $@
	fi
}

send_reboot_box()
{
	send_command_box r n 192.168.1.100 openwrt-broadcom-6836-vmlinux-initramfs-rd.elf  noramdisk 96836.dtb 0x04000000
}

alias csdk='cd ~/dev/sdk'
alias control-center='unset XDG_CURRENT_DESKTOP; gnome-control-center &>/dev/null &'
alias ssh-registry='ssh docker@192.168.100.238'
alias mtail-sdk='mtail -f make_log1.rej -w "==== My Marker MGH ===="'
alias connect_box='sudo ifconfig box0 {192.168.1.100,down,up}'
alias findn='find -name'
alias search-package='dpkg -S '

make_verbose()
{
	[ -f make_log1.rej ] && cp make_log1.rej make_log1.bak.rej
	dmake $@ V=sc -j1 --trace >make_log1.rej
	cp make_log1.rej make_log1.cpy.rej
}
if type -f _completion_loader &>/dev/null; then
	_completion_loader make
	complete -F _make make_verbose
fi

make_single_package()
{
	[ ${1:0:1} = "-" ] || {
		dmake $@ || exit $?
		shift
	}
	dmake $@ package/install || exit $?
	dmake $@ target/install	 || exit $?
	dmake $@ package/index	 || exit $?
	dmake $@ checksum
}

open-any()
{
	xdg-open $@ &>/dev/null &
}