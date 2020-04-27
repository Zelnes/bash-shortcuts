bash_path=$(realpath $(dirname ${BASH_SOURCE[0]})/..)

TMP=/tmp/bash_function_temporary
mkdir -p ${TMP}

# source "${bash_path}/git/git_functions.sh"

PROMPT_COMMAND='update_PS1'

# Retrieve the time HH:MM:SS
function get_datePS1()
{
    my_datePS1=$(date "+[%T]")
}

# Takes two arguments:
# The first one is the text that needs to be colored
# The second one is the color to use
# More info at https://misc.flogisoft.com/bash/tip_colors_and_formatting
function color_text()
{
    echo -ne "\001\e[38;5;$2m\002$1\001\e[0m\002"
}

function reverse_color_text()
{
    echo -ne "\001\e[7m\002$1\001\e[27m\002"
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
    if [ ! -f ${TITLE_FILE} ]; then
        _echo_title "$1"
    fi
}

# Changes the terminal title statically
function set_static_title()
{
    echo "$1" >${TITLE_FILE}
    _echo_title "$(cat ${TITLE_FILE})"
}
export -f set_static_title

function unset_static_title()
{
    rm -f ${TITLE_FILE}
}

function update_PS1()
{
    __status=$?

    # Update functions
    get_datePS1
    get_gitPS1
    get_svnPS1

    # _my_userPS1=$(whoami)
    # my_userPS1=$(color_text "[${_my_userPS1}]" 83)

    _my_pwdPS1=$(pwd | sed "s#$HOME#~#" | sed -E "s#([^/])[^/]+/#\1/#g")
    my_pwdPS1=$(color_text "[${_my_pwdPS1}]" 103)

    my_datePS1=$(color_text "${my_datePS1}" 244)
    [ $__status -eq 0 ] || my_datePS1="$(reverse_color_text "$my_datePS1")"
    my_gitPS1=$(color_text "${my_gitPS1}" 167)
    my_svnPS1=$(color_text "${my_svnPS1}" 128)
    my_shellLVLPS1="$(echo $SHLVL | sed 's/^1$//; t; s/.*/[SH:&]/')"
    my_shellLVLPS1=$(color_text "${my_shellLVLPS1}" 120)
    my_SSHPS1=${SSH_TTY:+[ssh]}
    my_SSHPS1="$(color_text "${my_SSHPS1}" 12)"

    local _txt_color="\001\e[38;5;110m\002"
    PS1='${my_SSHPS1}${my_shellLVLPS1}${my_userPS1}${my_datePS1}${my_gitPS1}${my_svnPS1}:${my_pwdPS1}$ '
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
function cd() {
    _OLDPWD=$OLDPWD
    command cd "$@"
}
function bcd() {
    cd "$OLDPWD"
}
function bbcd() {
    [ "$_OLDPWD" = "$PWD" ] && return
    cd "$_OLDPWD"
}
export -f cd bcd bbcd

alias grep='grep --color=auto'

alias m='emacsclient -nq'

# export LESS="-R -M -J -F"
batless() {
    if which bat &>/dev/null; then
        bat --color always "$@" | less -R
    else
        less "$@"
    fi
}

export LESS_TERMCAP_mb=$'\e[01;31m'
export LESS_TERMCAP_md=$'\e[01;38;5;74m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[04;38;5;146m'

# $1 : Pattern to match
# $>1 : files to parse
correspondant_endif() {
    local pattern="$1"; shift
    awk -v pat="$pattern" '
      BEGIN {
        another=0;
        support=0;
      }
      function PCL() {
        printf("[%s:%4.0d]:%s\n", FILENAME, NR, $0);
      }
      /^#if/ {
        if ($0 ~ pat)
          PCL();
        else
          another++;
      }
      /^#endif/ {
        if (another > 0)
          another--;
        else
          PCL();
      }' "$@"
}

docker-clean()
{
    docker rm $(docker ps -a | awk '/^[^C]/{print $NF}')
}

# export LANG=C

search_for_pattern() {
    local pat="$1"
    for i in $(rg -l "$pat"); do
        awk -v pat="$pat" '
          BEGIN {
            brack=0;
          }
          function saveLine() {
            stArea[idx++] = "/*["FILENAME":"NR"]*/"$0;
          }
          function print_array(i, s, f) {
            print "-----------------";
            for(i in stArea) {
              s = " "
              for (f in found)
                if (stArea[i] ~ ":"found[f])
                    s = "*"
              print s stArea[i];
            }
          }
          /{/ { brack++; }
          /}/ { brack--; }
          brack == 0 {
            if (found[1]) {
              saveLine();
              print_array();
            }
            delete stArea;
            idx = 1;
            delete found;
            idxF = 1;
          }
          {
            saveLine();
          }
          $0 ~ pat {
            found[idxF++] = NR;
          }' $i; done
}

chr() {
    [ "$1" -lt 256 ] || return 1
    printf "\\$(printf '%03o' "$1")"
}

ord() {
    LC_CTYPE=C printf '%d' "'$1"
}

# Function that will open each rej that a "quilt push -f" generated
# When the editor is done with a rej, rm it and open the next
# When no more rej is to be open launch "quilt refresh"
quilt_atom_fix_rej() {
    local i;
    for i in $(find -name '*.rej'); do
        ( set -x; atom --wait $i; rm $i; );
    done && quilt refresh
}
