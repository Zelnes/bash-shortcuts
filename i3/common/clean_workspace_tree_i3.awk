BEGIN {
	SEP=","
	SWALLOWS["Firefox-esr"] = "instance"
	SWALLOWS["Spotify"] = "instance"
	SWALLOWS["Pidgin"] = "instance"
	SWALLOWS["Gajim"] = "instance"
	SWALLOWS["Skype"] = "instance"
	SWALLOWS["Gnome-terminal"] = "instance"
	_keys = ""
}

# Remove the double '\'
{
	gsub(/\\/, "")
}

# Find the class
$2 ~ /"class":/ {
	gsub(/,$/, "", $3)
	for (i in SWALLOWS) {
		if ($3 ~ i) {
			# printf("List of fields needed for %s : %s\n", i, SWALLOWS[i])
			# split(SWALLOWS[i], filter, SEP)
			filter = SWALLOWS[i]
		}
	}
	key = $2
	add_key(key)
}

function add_key(key) {
	t1 = $1
	t2 = $2
	$1 = $2 = ""
	val = $0
	$1 = t1
	$2 = t2
	gsub(/,$/, "", val)

	if (_keys)
		_keys = _keys ","

	_keys = _keys key val
}

function flush_keys() {
	print _keys
	_keys = ""
	filter = ""
}

function has_keys() {
	return (_keys != "")
}

/\/\// {
	# printf("\"_comment\":'%s'\n", $0)
	# printf("'%s'\n", $0)
	if (filter) {
		key = $2
		gsub(/[":^$]/, "", $2)
		if (index(filter, $2)) {
			add_key(key)
		}
	}
	# else skip the comment
	next
}

{
	if (has_keys())
		flush_keys()
	print
}