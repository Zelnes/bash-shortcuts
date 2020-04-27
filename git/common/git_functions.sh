
CAN_USE_GIT_COMPLETION="n"
[ -f /usr/share/bash-completion/completions/git ] && {
    source /usr/share/bash-completion/completions/git
    CAN_USE_GIT_COMPLETION="y"
}

BRANCH=""

# This function gets a branch name
# If a parameter is given, then the branch returned
# is the first that contains the parameter (can be regex)
# For example :
# $ git branch -a
# master
# 160_branch
# 160_branch_mgh
# 158_branch
# $ get_git_branch 160
# 160_branch
# $ get_git_branch 160.*mgh
# 160_branch_mgh
# $ get_git_branch 158
# 158_branch
get_git_branch()
{
    local br="$1"
    if [[ -z "$br" ]]
    then
        git branch 2>/dev/null | sed -n '/^*/s/*[[:blank:]]*//p'
    else
        # Sed :
        #  - pattern match br (bash parameter expansion, to prevent char '/' from branch pattern)
        #  - Only keep what follows the last blank or "remotes/"
        #  - print the line and exit (the first match only is kept)
        git branch -a 2>/dev/null | sed -rn "/${br//\//\\/}/{s|.*[[:blank:]]+(remotes/)?||;p;q}"
    fi
}

# Test if current directory is a git one
# If not, my_gitPS1 is set to ""
# If yes, retrieves the branch name
# and then test if the repo have been modified (and needs commit(s))
# If the repo is not 'clean', the "git" prompt color is reversed
get_gitPS1()
{
    [ "${NO_GIT_PS1}" = "y" ] && {
        my_gitPS1=""
        return 0
    }

    git rev-parse --git-dir &>/dev/null
    local __st=$?
    if [[ $__st -eq 0 ]]
    then
        BRANCH=`get_git_branch`
        if [[ ${#BRANCH} -gt 15 ]]
        then
            # If the branch is a SDK, it is cut to print only story/SDK-NUMBER
            # Otherwise, if it's length is greater than 15 it is cut to this length
	    BRANCH=`echo $BRANCH | sed -r 's/([A-Z]+-#?[0-9]+).*/\1/; t; s/(.{15}).*/\1/'`
        fi
        STATUS=`git status --porcelain`
        if [[ ${#STATUS} -ne 0 ]]
        then
            # Reverse 'git' color to show change
            __git="$(reverse_color_text git)"
        else
            __git="git"
        fi
        my_gitPS1="[$__git $BRANCH]"
    else
        my_gitPS1=""
    fi
    # echo $my_gitPS1
}

# Same as get_gitPS1(), except that nothing is done
# yet to show if the repo is clean or not
get_svnPS1()
{
    local __infos=`svn info 2>/dev/null`
    if [[ "$__infos" != "" ]]
    then
        BRANCH=`echo $__infos | sed -e 's/.*branches\///' -e 's/ .*//'`
        my_svnPS1="[svn $BRANCH]"
    else
        my_svnPS1=""
    fi
}

# Goes to N-th git parent directory, if exists, are the last git directory encountered
git_cd_n()
{
    local cddir="."
    local firstPD=""
    local gitD=""

    for i in $(seq 1 $1); do
        firstPD=$(cd $cddir && git rev-parse --show-toplevel 2>/dev/null)
        if [[ ! -z "$firstPD" ]]
        then
            cddir="$firstPD"/..
            gitD="$firstPD"
        else
            break
        fi
    done

    if [[ ! -z "$gitD" && "$gitD" != "$(pwd)" ]]; then
        cd $gitD
    fi
}
export -f git_cd_n

# Change directory to git top level directory
# Example : /home/me/my_git is a git directory, ie it contains .git
# $ cd /home/me/my_git
# $ cd src/test # --> pwd : /home/me/my_git/src/test
# $ gcd # --> pwd : /home/me/my_git
alias gcd='git_cd_n 1'

# Change directory from a git package directory to it's parent git root
# Example : /my_git is a git dir, contains feeds/my_package which is a git dir too
# $ cd /my_git/feeds/my_package/another/directory # pwd -->/my_git/feeds/my_package/another/directory
# $ pgcd # pwd --> /my_git
alias pgcd='git_cd_n 2'

# Prints one-lined log. Must be used with it's first argument being a number
# Example : glog 2 # And can be completed with 'git log' other arguments
alias glog='git log --oneline -n '
[ "${CAN_USE_GIT_COMPLETION}" == "y" ] && __git_complete glog _git_log

# Prints git status with short output (by default)
# Can be completed with 'git status' other arguments
alias gst='git -c color.status=always status -s | awk "{print NR\"\t\"\$0}"'

get_git_ticket_ref()
{
    local b
    if [[ -z "$1" ]]; then
        b=`get_git_branch`
    else
        b=${1}
    fi
    echo ${b} | grep -o -E "[A-Z]+-#?[0-9]+"
}

gplog()
{
    local _issue=${1:-$(get_git_ticket_ref)}
    echo "issue : $_issue"
    shift
    git log --grep="${_issue}" $@
}
[ "${CAN_USE_GIT_COMPLETION}" == "y" ] && __git_complete gplog _git_log

# Commits the last changes with a prefix for SDK commits
# It will execute this command :
# $ gcommit "My message" I want to commit
# git commit -m "SDK-160 My message I want to commit"
# if my current branch is story/SDK-160-anything
# Works for NBX-NUMBER ;) # Tested on nbx/feature/branding_NBX-3579_webui branch on trunk-next
gcommit()
{
    local branch=`get_git_branch`
    if [[ ! -z "$branch" ]]
    then
        if [[ ! -z "$1" ]]
        then
            local _issue=`get_git_ticket_ref ${branch}`
            [ -n "$_issue" ] && _issue="$_issue "
            # echo $_issue
            local _cmd="git commit -m \"${_issue}$@\""
            echo $_cmd
            eval "$_cmd"
        else
            echo "No argument given. Exiting..."
            return 1
        fi
    else
        echo "Not a git directory. Exiting..."
        return 1
    fi
}
[ "${CAN_USE_GIT_COMPLETION}" == "y" ] && __git_complete gcommit _git_commit

# Sends and executes a command on all the terms opened
# It needs ttyecho
send_command_to_all_terminal()
{
    if [[ -z "`which ttyecho`" ]]; then
        echo "ttyecho not found. Exiting..."
        return 1
    fi

    local device=$(for p in $(pidof bash); do readlink -f /proc/$p/fd/0; done | sort -u)

    for d in $device
    do
        if [[ $d == /dev/pts/* ]]
        then
            ttyecho -n $d $@
        fi
    done
    # ttyecho -n
}

# Source the bashrc in the home directory
source_home()
{
    source ~/.bashrc
}

# Resource all terms opened with the ~/.bashrc
# useful when a command is updated and needs to be present
# on all terms
source_all()
{
    send_command_to_all_terminal source ~/.bashrc
}

# Push a git branch to it's upstream branch on the server
# If no paramater, the current branch is pushed
# Otherwise, same behaviour as get_git_branch to retrieve a branch name
# And the paramater given is the one used to set the branch to push
gpush()
{
    local force=""
    if [[ "$1" = "-f" ]]; then
        force="-f"
        shift
    elif [[ "$2" = "-f" ]]; then
        force="-f"
    fi

    local branch=`get_git_branch "$1"`
    if [[ -z "$branch" ]]
    then
        echo "No branch found for pattern $1"
        return 1
    fi
    shift
    local remote=$(git remote | head -n 1)
    cmd="git push ${force} $@ ${remote} $branch:`git rev-parse --symbolic-full-name $branch@{upstream} | sed -r "s#.*/${remote}/##"`"
    echo $cmd
    eval $cmd
}
[ "${CAN_USE_GIT_COMPLETION}" == "y" ] && __git_complete gpush _git_push

# Same behaviour as get_git_branch to retrieve a branch name
# Then checkouts on the given branch
gcheckout()
{
    local remote=$(git remote | head -n 1)
    local branch=`get_git_branch "$1" | sed -r "s#.*${remote}/##"`
    if [[ -z "$branch" ]]
    then
        echo "No branch found for pattern $1"
        return 1
    fi
    git checkout "$branch"
}
[ "${CAN_USE_GIT_COMPLETION}" == "y" ] && __git_complete gcheckout _git_checkout

# This function retrieves the list of modified files
# It's first argument is the 'git status' mode (option u)
# and the others arguments are the numbers that represents
# the files to keep in the list
# If an argument is not a number or 0, it is ignored
# The index starts at 1 to N
get_git_modified_files()
{
    local _mfiles=$(git status -s -u${1} | awk "{print \$NF}")
    shift 1
    local _aMfiles=($_mfiles)
    local _finalFiles=""

    if [[ $# -eq 0 ]]
    then
        echo ${_mfiles}
    else
        for i in $@
        do
            if [[ "$i" =~ ^[0-9]+$ && "$i" -ne 0 ]]
            then
                _finalFiles+="${_aMfiles[$(($i - 1))]} "
            fi
        done
        echo ${_finalFiles}
    fi
}

# Execute a 'git status -s' then a git diff on the file(s)
# If the given argument is a number, then the file
# shown on the corresponding line is diff'ed
# If no argument is given, git diff is performed
# If non-number argument is given, nothing is done
# Only the first parameter is taken into account
gstd()
{
    local _mfiles

    # The mode for the status is 'no' because we only want tracked files to be diff'ed
    _mfiles=$(get_git_modified_files no $@)

    if [[ ! -z "${_mfiles}" ]]
    then
        git diff ${_mfiles}
    fi
}

# Execute a 'git checkout' on the specified file(s), represented
# by their gst's index (see get_git_modified_files's doc)
#
gstc()
{
    if [[ $# -eq 0 ]]
    then
        echo "Missing argument. Exiting..."
        return 1
    fi

    local _mfiles

    # The mode for the status is 'no' because we only want tracked files to be check'ed out
    _mfiles=$(get_git_modified_files no $@)

    if [[ ! -z "${_mfiles}" ]]
    then
        git checkout ${_mfiles}
        echo "Checked out : ${_mfiles}"
    fi
}

# Returns the names of the given index, based on gst output
gstn()
{
    # The mode is 'normal' because we possibly want to add any file
    get_git_modified_files normal $@
}


gadd()
{
    if [[ $# -eq 0 ]]
    then
        echo "Missing argument. Exiting..."
        return 1
    fi

    local _mfiles

    # The mode is 'normal' because we possibly want to add any file
    _mfiles=$(get_git_modified_files normal $@)

    if [[ ! -z "${_mfiles}" ]]
    then
        git add --verbose ${_mfiles}
        echo "Added : ${_mfiles}"
    fi
}

# Perform a git commit --amend
# Eventually, if $1 is -n then it does it with --no-edit option
gamend()
{
    local no
    if [[ "${1}" = "-n" ]]; then
        no="--no-edit"
    fi
    git commit --amend ${no}
}

# Will print, for each current modified files, every commit
find_commits_for_changed_files() {
    local possible_branch_origin=$(git log --format="%D" | sed -rn '; /^origin\/l?sdk-dev/{s/,.*$//;p;q}')
    local branchFrom=${1:-${possible_branch_origin}}
    local files=$(git status --short -uno | awk '{c = c "," $NF} END { print c }')
    # files starts with a comma, remove it when passing it to awk
    git log --name-only --format="__sep__ %h" "${branchFrom}".. | awk -v files="${files/,/}" '
        BEGIN {
            RS = "__sep__";
            CSEP = " "
            split(files, arrF, ",")
        }
        NF == 0 { next; }

        {
            commit = $1
            for (i = 2; i <= NF; ++i) {
              for (j in arrF) {
                if ($i == arrF[j]) {
                  arr[$i] = arr[$i] commit CSEP;
                }
              }
            }
        }
        END {
        for (i in arr)
          printf("%s: ", i);
          if (arr[i])
            print(arr[i])
          else
            print "None"
        }
    '
}