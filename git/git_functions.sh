
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
function get_git_branch()
{
    local branch="$1"
    if [[ -z "$branch" ]]
    then
        git branch -a 2> /dev/null | sed -e '/^[^*]/d' -e 's/* //'
    else
        git branch -a | grep -E "$branch" | grep -oE '[^ ]+$' | sed -r -e 's#remotes/origin/##' | head -n1
    fi
}

# Test if current directory is a git one
# If not, my_gitPS1 is set to ""
# If yes, retrieves the branch name
# and then test if the repo have been modified (and needs commit(s))
# If the repo is not 'clean', the "git" prompt color is reversed
function get_gitPS1()
{
    git rev-parse --git-dir &>/dev/null
    local __st=$?
    if [[ $__st -eq 0 ]]
    then
        BRANCH=`get_git_branch`
        if [[ ${#BRANCH} -gt 15 ]]
        then
            # If the branch is a SDK, it is cut to print only story/SDK-NUMBER
            # Otherwise, if it's length is greater than 15 it is cut to this length
            BRANCH=`echo $BRANCH | sed -r 's/(SDK-[0-9]+).*/\1/' | sed -r 's/(.{15}).*/\1/'`
        fi
        STATUS=`git status --porcelain`
        if [[ ${#STATUS} -ne 0 ]]
        then
            # Reverse 'git' color to show change
            __git="\001\e[7m\002git\001\e[27m\002"
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
function get_svnPS1()
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

# Prints git status with short output (by default)
# Can be completed with 'git status' other arguments
alias gst='git status -s'

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
            local _issue=`echo $branch | sed -r 's/.*[^a-zA-Z]([a-zA-Z]+-[0-9]+).*/\1/'`
            # echo $_issue
            local _cmd="git commit -m \"$_issue $@\""
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

# Sends and executes a command on all the terms opened
# It needs ttyecho
send_command_to_all_terminal()
{
    if [[ -z "`which ttyecho`" ]]; then
        echo "ttyecho not found. Exiting..."
        return 1
    fi
    
    local device=`for p in $(pidof bash); do readlink -f /proc/$p/fd/0; done | sort -u`

    for d in $device
    do
        if [[ $d == /dev/pts/* ]]
        then
            ttyecho -n $d $@
        fi
    done
    # ttyecho -n
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
    local branch=`get_git_branch "$1"`
    if [[ -z "$branch" ]]
    then
        echo "No branch found for pattern $1"
        return 1
    fi
    cmd="git push origin $branch:`git rev-parse --symbolic-full-name $branch@{upstream} | sed -r 's#.*/origin/##'`"
    echo $cmd
    eval $cmd
}

# Same behaviour as get_git_branch to retrieve a branch name
# Then checkouts on the given branch
gchekcout()
{
    local branch=`get_git_branch "$1"`
    if [[ -z "$branch" ]]
    then
        echo "No branch found for pattern $1"
        return 1
    fi
    git checkout "$branch"
}

# This function retrieves the list of modified files
# It's first argument is the 'git status' mode (option u)
# and the others arguments are the numbers that represents
# the files to keep in the list
# If an argument is not a number or 0, it is ignored 
# The index starts at 1 to N
get_git_modified_files()
{
    local _mfiles=$(git status -s -u${1} | awk "{print \$2}")
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
    fi
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
        git add ${_mfiles}
    fi
}
