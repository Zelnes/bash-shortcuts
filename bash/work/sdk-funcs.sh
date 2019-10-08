# Some functions usefull

__quiet() {
	# Pass all nvram locks to off
	nvram list lock | awk -F= '/=on/{system("echo nvram set " $1 " off")}'

	dmesg -n 1; ls /tmp/autoconf; tail -f /var/log/daemon.log
}

copy2box ()
{
	local from="$1";
	local to="$2";
	sshpass -ptfmdev scp -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null -P1288 "$from" root@192.168.1.1:"$to"
}

cmd2box()
{
	sshpass -ptfmdev ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null -p1288 root@192.168.1.1 "$@"
}

copyfrombox ()
{
	local from="$1";
	local to="$2";
	sshpass -ptfmdev scp -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null -P1288 root@192.168.1.1:"$from" "$to"
}