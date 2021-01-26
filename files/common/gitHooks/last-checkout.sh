#!/bin/bash
[ "$1" = "-v" ] && set -x

# Current Directory
dir=$(git rev-parse --show-toplevel) || exit
dir=$(echo $dir | sed 's|/|!|g')

# Last Branch File
eval lbf=$(git config --get core.hookspath)/.last_branch
lbf=$(realpath $lbf)
touch $lbf

# Last known hash
hash=$(awk -v CD=$dir '($0~"^"CD" "){print $2}' $lbf)
[ -z "$hash" ] && {
    echo "No history for last branch..."
    exit 1
}

# bn=$(git branch --contains $hash)
# [ "$hash" != "$(git rev-parse $bn)" ] && bn=$hash

[ "$1" = "-l" ] && do_echo=echo
$do_echo git checkout "$hash"
