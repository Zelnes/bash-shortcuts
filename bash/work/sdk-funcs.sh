# Some functions usefull

__quiet() {
	# Pass all nvram locks to off
	nvram list lock | awk -F= '/=on/{system("echo nvram set " $1 " off")}'

	dmesg -n 1; ls /tmp/autoconf; tail -f /var/log/daemon.log
	serialization --magic nEuFbOxFaBeFiXo
}

BOX_OPTS="-o LogLevel=ERROR -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null"

copy2box ()
{
	local to="$1"; shift
	local ip=${IP:-192.168.1.1}
	sshpass -ptfmdev scp ${OPT} ${BOX_OPTS} -P1288 "$@" root@$ip:"$to"
}

cmd2box()
{
	local ip=${IP:-192.168.1.1}
	sshpass -ptfmdev ssh ${OPT} ${BOX_OPTS} -p1288 root@$ip "$@"
}

copyfrombox ()
{
	local to="$1"; shift
	local from="$@";
	local ip=${IP:-192.168.1.1}
	sshpass -ptfmdev scp ${OPT} ${BOX_OPTS} -P1288 root@$ip:"$from" "$to"
}

runonbox()
{
	local ip=${IP:-192.168.1.1}
	echo "root@$ip:\$ $*"
	sshpass -ptfmdev ssh ${OPT} ${BOX_OPTS} -p1288 root@$ip "$*"
}