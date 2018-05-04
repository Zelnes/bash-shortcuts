bash_path=$(realpath $(dirname ${BASH_SOURCE[0]})/..)

TMP=${bash_path}/tmp
mkdir -p ${TMP}

# source "${bash_path}/git/git_functions.sh"

PROMPT_COMMAND='update_PS1'

# Retrieve the time HH:MM:SS
function get_datePS1()
{
    my_datePS1=`date "+[%T]"`
}

# Takes two arguments:
# The first one is the text that needs to be colored
# The second one is the color to use
# More info at https://misc.flogisoft.com/bash/tip_colors_and_formatting
function color_text()
{
    echo -ne "\001\e[38;5;$2m\002$1\001\e[0m\002"
}

# The title state
TITLE_STATE="reset"
TITLE_FILE=${TMP}/$$

# Function that sets effectively the title
function _echo_title()
{
    echo -ne "\033]0;${1}\007"
}

# Changes the terminal title
# The first argument set the title state
# If it is "static" then the title won't change
# If it is "reset" then the title we'll be reset
#   and will be updatable with a dynamic change
# If it is "dynamic" then the title will change
#   only if it was not in a static state
function _set_title()
{
    if [[ ! -f ${TITLE_FILE} ]]; then
        _echo_title "$1"
    fi
}

# Changes the terminal title statically
function set_static_title()
{
    echo "$1" >${TITLE_FILE}
    _echo_title "$(cat ${TITLE_FILE})"
}

function unset_static_title()
{
    rm -f ${TITLE_FILE}
}

function update_PS1()
{
    __status=$?
    # Update History
    history -a
    history -n

    # Update functions
    get_datePS1
    get_gitPS1
    get_svnPS1

    # _my_userPS1=`whoami`
    # my_userPS1=`color_text "[${_my_userPS1}]" 83`

    _my_pwdPS1=`pwd | sed "s#$HOME#~#" | sed -E "s#([^/])[^/]+/#\1/#g"`
    my_pwdPS1=`color_text "[${_my_pwdPS1}]" 103`

    my_datePS1=`color_text "${my_datePS1}" 244`
    my_gitPS1=`color_text "${my_gitPS1}" 167`
    my_svnPS1=`color_text "${my_svnPS1}" 128`

    local _txt_color="\001\e[38;5;110m\002"
    PS1='${my_userPS1}${my_datePS1}${my_gitPS1}${my_svnPS1}:${my_pwdPS1}$ '
    _set_title "${_my_pwdPS1}"
}

# Change directory to the previous one
# Example :
# $ pwd
# /home/me
# $ cd /tmp # --> pwd = /tmp
# $ bcd # --> pwd = /home/me
# $ bcd # --> pwd = /tmp
# Same as 'cd -' but, for me, faster to type
alias bcd='cd $OLDPWD'
