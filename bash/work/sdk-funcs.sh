# Some functions usefull

__quiet() {
	# Pass all nvram locks to off
	nvram list lock | awk -F= '/=on/{system("echo nvram set " $1 " off")}'

	dmesg -n 1
	ls /tmp/autoconf
	tail -f /var/log/daemon.log
}

BOX_OPTS="-o LogLevel=ERROR -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null"

copy2box() {
	local to="$1"
	shift
	local ip=${IP:-192.168.1.1}
	sshpass -ptfmdev scp ${OPT} ${BOX_OPTS} -P1288 "$@" root@$ip:"$to"
}

cmd2box() {
	local ip=${IP:-192.168.1.1}
	sshpass -ptfmdev ssh ${OPT} ${BOX_OPTS} -p1288 root@$ip "$@"
}

copyfrombox() {
	local to="$1"
	shift
	local from="$@"
	local ip=${IP:-192.168.1.1}
	sshpass -ptfmdev scp ${OPT} ${BOX_OPTS} -P1288 root@$ip:"$from" "$to"
}

runonbox() {
	local ip=${IP:-192.168.1.1}
	echo "root@$ip:\$ $*"
	sshpass -ptfmdev ssh ${OPT} ${BOX_OPTS} -p1288 root@$ip "$*"
}

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
(
	git_cd_n # go back to the higher git directory, hopefully it is sdk
	[ ! -f .current_board ] && {
		>&2 echo "No current board/target known in $(pwd)"
		exit 1
	}
	"$@"
)

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
alias dock='set_static_title Docker; cd /home/mgh/dev/dockerfiles'

sdk() {
	# If $1 is given, prepend a "-" sign
	local orig="$1"

	set_static_title "SDK${orig:+ $orig}"
	cd "/home/mgh/dev/sdk${orig:+-$orig}"
}

dsb_packages() {
	# If $1 is given, prepend a "-" sign
	local orig="$1"

	set_static_title "DSB Packages${orig:+ $orig}"
	cd "/home/mgh/dev/sdk${orig:+-$orig}-feeds/dsb_packages"
}


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
	local ip="${IP:-192.168.1.1}"

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
	curl -o /dev/null -F"filename=@${img}" "http://$ip/upload.cgi"
}

alias refresh='xset dpms force suspend'

mgh_picocom_connect()
{
	local dev=$1
	[[ "$dev" =~ ^[0-9]+$ ]] && dev=/dev/ttyUSB${dev}
	[ -e "$dev" ] && picocom -b 115200 $dev
}

mgh_picocom() {
	local i

	set_static_title "Picocom BOX"
	# Will try to connect to serial port on /dev/ttyUSB0 with a baudrate of 115200
	if [[ $# -eq 1 ]]; then
		mgh_picocom_connect "$1"
	else
		for i in /dev/ttyUSB*; do
			mgh_picocom_connect "$i" && break
		done
	fi
}