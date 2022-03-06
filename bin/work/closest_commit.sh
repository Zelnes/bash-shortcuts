#!/bin/bash

# This script list the number of differences between a file File1 and a versionned file File2
# in order to find out which commit is the closest one to the actual File1

STATE_DIR="/tmp/state_dir"

# $1 path to the file not versionned
ngit_file="$(basename "$1")"
ngit_dir="$(realpath $(dirname "$1"))"
# $2 path to the file versionned
git_file="$(basename "$2")"
git_dir="$(realpath $(dirname "$2"))"

mkdir -p "${STATE_DIR}"

git log ${git_file} | grep ^commit | awk '{print $2}' | \
    xargs -n1 -I_p bash -c "git show _p:${git_file} >${STATE_DIR}/state_${file}._p && diff ../mmc-utils/${file} ${STATE_DIR}/state_${file}._p >${STATE_DIR}/diff_${file}._p"

find ${STATE_DIR}/ -name diff_${file}.* -not -type d | \
    xargs -n1 -I_p bash -c "echo -n '_p : '; cat _p | wc -l" | sort -n -k3

rm -rf "${STATE_DIR}"