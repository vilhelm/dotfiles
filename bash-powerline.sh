#!/usr/bin/env bash

__powerline() {
    # Unicode symbols
    PS_SYMBOL='\$'
    GIT_BRANCH_SYMBOL=''
    GIT_BRANCH_CHANGED_SYMBOL='+'
    GIT_NEED_PUSH_SYMBOL='⇡'
    GIT_NEED_PULL_SYMBOL='⇣'
    SEPARATOR=''
    SEPARATOR_THIN=''

    # Solarized colorscheme
    FG_BASE03="\[\e[90m\]"
    FG_BASE02="\[\e[30m\]"
    FG_BASE01="\[\e[92m\]"
    FG_BASE00="\[\e[93m\]"
    FG_BASE0="\[\e[94m\]"
    FG_BASE1="\[\e[96m\]"
    FG_BASE2="\[\e[37m\]"
    FG_BASE3="\[\e[97m\]"

    BG_BASE03="\[\e[100m\]"
    BG_BASE02="\[\e[40m\]"
    BG_BASE01="\[\e[102m\]"
    BG_BASE00="\[\e[103m\]"
    BG_BASE0="\[\e[104m\]"
    BG_BASE1="\[\e[106m\]"
    BG_BASE2="\[\e[47m\]"
    BG_BASE3="\[\e[107m\]"

    FG_ORANGE="\[\e[31m\]"
    FG_GREEN="\[\e[32m\]"
    FG_YELLOW="\[\e[33m\]"
    FG_BLUE="\[\e[34m\]"
    FG_MAGENTA="\[\e[35m\]"
    FG_CYAN="\[\e[36m\]"
    FG_RED="\[\e[91m\]"
    FG_VIOLET="\[\e[95m\]"

    BG_ORANGE="\[\e[41m\]"
    BG_GREEN="\[\e[42m\]"
    BG_YELLOW="\[\e[43m\]"
    BG_BLUE="\[\e[44m\]"
    BG_MAGENTA="\[\e[45m\]"
    BG_CYAN="\[\e[46m\]"
    BG_RED="\[\e[101m\]"
    BG_VIOLET="\[\e[105m\]"

    DIM="\[\e[2m\]"
    REVERSE="\[\e7m\]"
    RESET="\[\e[0m\]"
    BOLD="\[\e[1m\]"

    __git_info() {
        [ -x "$(which git)" ] || return    # no git command found

        # get current branch name or short SHA1 hash for detached head
        local branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
        [ -n "$branch" ] || return  # not a git branch

        local marks

        # branch is modified?
        [ -n "$(git status --porcelain)" ] && marks+=" $GIT_BRANCH_CHANGED_SYMBOL"

        # how many commits local branch is ahead/behind of remote?
        local stat="$(git status --porcelain --branch | grep '^##' | grep -o '\[.\+\]$')"
        local aheadN="$(echo $stat | grep -o 'ahead [0-9]\+'| grep -o '[0-9]\+')"
        local behindN="$(echo $stat | grep -o 'behind [0-9]\+' | grep -o '[0-9]\+')"
        [ -n "$aheadN" ] && marks+=" $GIT_NEED_PUSH_SYMBOL$aheadN"
        [ -n "$behindN" ] && marks+=" $GIT_NEED_PULL_SYMBOL$behindN"

        # print the git branch segment without a trailing newline
        printf " $GIT_BRANCH_SYMBOL $branch$marks"
    }

    ps1() {
        local EXIT=$?
        PS1="$RESET"

        # Military time
        local BG=$BG_BASE1
        PS1+="$BG$FG_BASE3$BOLD\A"
        local FG=$FG_BASE1

        # user@host
        BG=$BG_BASE0
        PS1+="$FG$BG$SEPARATOR$RESET$BG$FG_BASE3 \u@\H"
        FG=$FG_BASE0

        # Path
        local CWD=$(pwd)
        CWD=${CWD/$HOME/\~}
        CWD=${CWD//\// $SEPARATOR_THIN }
        BG=$BG_BASE03
        PS1+="$FG$BG$SEPARATOR$RESET$BG $CWD"
        FG=$FG_BASE03

        # Git information
        local GITINFO=$(__git_info)
        if [[ -n "$GITINFO" ]]; then
            BG=$BG_BLUE
            PS1+="$FG$BG$SEPARATOR$FG_BASE3$GITINFO"
            FG=$FG_BLUE
        fi
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly.
        if [[ $EXIT == 0 ]]; then
            BG="$BG_GREEN"
            PS1+="$FG$BG$SEPARATOR$FG_BASE3 $PS_SYMBOL" # prompt symbol
            FG="$FG_GREEN"
        else
            BG=$BG_RED
            PS1+="$FG$BG$SEPARATOR$FG_BASE3 e=$EXIT $PS_SYMBOL"
            FG="$FG_RED"
        fi
        BG=$RESET
        PS1+="$BG$FG$SEPARATOR$RESET"
    }

    PROMPT_COMMAND=ps1
}

__powerline
unset __powerline
