#!/bin/sh

########
# SPAD #
########

# USAGE:
# spad [-l] [--md] [_tag_] - create spad with or without tag
# spad [-l] ls             - list spads
# spad [-l] grep           - search spads
# spad [-l] _index_        - open spad by index
# spad [-l] stdin [_tag_]  - put stdin into spad with or without tag
# spad [-l] cat _index_    - print spad to stdout
# spad [-l] rm _index_...  - delete spad by index
# spad [-l] day            - open spad for today

# TODO
# * spad stdin should work automatically

numeric() {
    if [[ "$1" =~ ^-?[0-9]+$ ]] ; then
        echo "1"
    else
        echo ""
    fi
}

err() {
    echo "$1" ; exit 1
}

listscratchpads() {
    find "$1" -maxdepth 1 \
        -type f \
        -name "*.txt" \
        -o -name "*.md" | sort
}

printspads() { # print by scratchpad title or index
    SCRATCHPADS="$1"
    CHOSEN_SCRATCHPADS="$2" # to choose scratchpads to print by title
    CHOSEN_INDICES="$3"     # to choose scratchpads to print by index

    INDEX_WIDTH=$(expr "$(echo "$SCRATCHPADS" | wc -w | wc -m)" - 1)
    TERM_SIZE=$(stty size)
    TERM_WIDTH=${TERM_SIZE##* }
    I=0
    # perhaps make this dryer. Put conditional inside loop...
    if [ "$CHOSEN_SCRATCHPADS" ] ; then # print chosen titles
        for S in $SCRATCHPADS ; do
            L=$(head -n 1 $S)
            if [ "$(echo "$CHOSEN_SCRATCHPADS" | grep "$S")" ] ; then
                LINE="$(printf "%0${INDEX_WIDTH}d" $I)) $SIZE ${S##*/}: $L"
                echo "${LINE:0:$TERM_WIDTH}"
            fi
            I=$(expr $I + 1)
        done
    elif [ "$CHOSEN_INDICES" ] ; then # print chosen indices
        for S in $SCRATCHPADS ; do
            L=$(head -n 1 $S)
            for CHOSEN_INDEX in $CHOSEN_INDICES ; do
                if [ "$I" -eq "$CHOSEN_INDEX" ] ; then
                    LINE="$(printf "%0${INDEX_WIDTH}d" $I)) ${S##*/}: $L"
                    echo "${LINE:0:$TERM_WIDTH}"
                    break
                fi
            done
            I=$(expr $I + 1)
        done
    else # print all
        for S in $SCRATCHPADS ; do
            L=$(head -n 1 $S)
            LINE="$(printf "%0${INDEX_WIDTH}d" $I)) ${S##*/}: $L"
            echo "${LINE:0:$TERM_WIDTH}"
            I=$(expr $I + 1)
        done
    fi
}

TIMESTAMP="$(date +%F-%T:%N)"
BASEDIR="$MY_SYNC/corpus/dump/scratchpad"
COMMAND="spad"
INDEX="" # check index assignment to make sure index is within range
INDICES=""
TAG=""
QUERY=""
EXT="txt"
TITLE=""

# global options
while [ "${1:0:1}" == "-" ] ; do
    case "$1" in
        "-l")
            BASEDIR="."
        ;;
        "--md")
            EXT="md"
            TITLE="# $TIMESTAMP"
        ;;
        *)
            err "unknown global option \"$1\""
        ;;
    esac
    shift
done

# command
if [ "$1" ] ; then
    for C in "ls" "grep" "stdin" "cat" "rm" "day" ; do
        if [ "$1" == "$C" ] ; then
            COMMAND="$C"
            shift
            break
        fi
    done
fi

# command options
while [ "${1:0:1}" == "-" ] ; do
    # this should be a command case statement around an option case
    # statement, which could get big very quickly
    case "$1" in
        *)
            err "unknown command ($COMMAND) option \"$1\""
        ;;
    esac
    shift
done

# command argument
if [ "$1" ] ; then
    case $COMMAND in
        "spad")
            if [ $(numeric "$1") ] ; then
                INDEX="$1"
            else
                TAG="$1"
            fi
        ;;
        "ls")
            err "command (ls) does not take an argument"
        ;;
        "grep")
            QUERY="$1"
        ;;
        "stdin")
            if [ $(numeric "$1") ] ; then
                err "command (spad) tag cannot be numeric"
            else
                TAG="$1"
            fi
        ;;
        "cat")
            if [ $(numeric "$1") ] ; then
                INDEX="$1"
            else
                err "command (cat) was not provided with an index"
            fi
        ;;
        "rm")
            while [ "$1" ] ; do
                if [ $(numeric "$1") ] ; then
                    # fix this syntax
                    # INDICES="$1 $INDICES" (??)
                    INDICES="$INDICES
$1"
                else
                    err "command (rm) was not provided with an index"
                fi
                shift
            done
        ;;
        "day")
            err "command (day) does not take an argument"
        ;;
    esac
fi

if [ "$TAG" ] ; then
    if [[ "$TAG" =~ ^.*[[:space:]].*$ ]] ; then
        err "tag cannot contain whitespace \"$TAG\""
    fi
    TAG="-$TAG"
fi

# action
case "$COMMAND" in
    "spad")
        if [ "$INDEX" ] ; then
            SCRATCHPADS=($(listscratchpads "$BASEDIR"))
            if [ "$INDEX" -lt "${#SCRATCHPADS[@]}" ] ; then
                $EDITOR "${SCRATCHPADS[$INDEX]}"
            else
                echo "Index outside range."
            fi
        else
            if [ "$TITLE" ] ; then
                echo $'# \n' > "$BASEDIR/$TIMESTAMP$TAG.$EXT"
            fi
            $EDITOR "$BASEDIR/$TIMESTAMP$TAG.$EXT" # and what if $EDITOR is not defined?
        fi
    ;;
    "ls")
        printspads "$(listscratchpads $BASEDIR)"
    ;;
    "grep")
        SCRATCHPADS=$(listscratchpads $BASEDIR)
        CHOSEN=$(grep -li -E "$QUERY" $SCRATCHPADS)
        if [ "$CHOSEN" ] ; then
            printspads "$SCRATCHPADS" "$CHOSEN"
        else
            echo "No matches found."
        fi
    ;;
    "stdin")
        cat /dev/stdin > "$BASEDIR/$TIMESTAMP$TAG.$EXT"
        echo "captured stdin"
    ;;
    "cat")
        SCRATCHPADS=($(listscratchpads "$BASEDIR"))
        cat "${SCRATCHPADS[$INDEX]}"
    ;;
    "rm")
        SCRATCHPADS=$(listscratchpads "$BASEDIR")
        printspads "$SCRATCHPADS" "" "$INDICES"
        echo "confirm rm scratchpads $INDICES? y/N"
        read -s -n 1 RESPONSE
        if [ "$RESPONSE" != 'y' ] ; then
            echo "aborted"
            exit 1
        fi
        SCRATCHPADS=($SCRATCHPADS) # how ugly
        for INDEX in $INDICES ; do
            rm "${SCRATCHPADS[$INDEX]}"
        done
    ;;
    "day")
        # > I don't like the c-note, Rosato. I take that as an insult.
        $EDITOR "$BASEDIR/$(date +%F-%A).txt"
    ;;
esac


