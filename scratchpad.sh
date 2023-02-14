#!/bin/sh

########
# SPAD #
########

HELP="USAGE:
spad [-l] [--md]          - create spad
spad [-l] ls              - list spads
spad [-l] grep            - search spads
spad [-l] _index_         - open spad by index
spad [-l] stdin           - put stdin into spad
spad [-l] cat _index_     - print spad to stdout
spad [-l] rm _index_...   - delete spad by index
spad [-l] day             - open spad for today
spad [-l] yday            - open spad for yesterday
spad [-l] nday            - open spad for tomorrow
spad [-l] note _notes_... - add a note to spad for today
spad --help               - print this message"

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
    if [[ "$CHOSEN_SCRATCHPADS" ]] ; then # print chosen titles
        for S in $SCRATCHPADS ; do
            L=$(head -n 1 $S)
            if [[ "$(echo "$CHOSEN_SCRATCHPADS" | grep "$S")" ]] ; then
                LINE="$(printf "%0${INDEX_WIDTH}d" $I)) ${S##*/}: $L"
                echo "${LINE:0:$TERM_WIDTH}"
            fi
            I=$(expr $I + 1)
        done
    elif [[ "$CHOSEN_INDICES" ]] ; then # print chosen indices
        for S in $SCRATCHPADS ; do
            L=$(head -n 1 $S)
            for CHOSEN_INDEX in $CHOSEN_INDICES ; do
                if [[ "$I" -eq "$CHOSEN_INDEX" ]] ; then
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
QUERY=""
EXT="txt"
TITLE=""
NOTE=""
EDITOR="${EDITOR:-vi}"

# global options
while [[ "${1:0:1}" == "-" ]] ; do
    case "$1" in
        "-l")
            BASEDIR="."
        ;;
        "--md")
            EXT="md"
            TITLE="# $TIMESTAMP"
        ;;
        "--help")
            echo "$HELP"
            exit 0
        ;;
        *)
            err "unknown global option \"$1\""
        ;;
    esac
    shift
done

# command
if [[ "$1" ]] ; then
    for C in "ls" "grep" "stdin" "cat" "rm" "day" "yday" "nday" "note" ; do
        if [[ "$1" == "$C" ]] ; then
            COMMAND="$C"
            shift
            break
        fi
    done
fi

# command options
while [[ "${1:0:1}" == "-" ]] ; do
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
if [[ "$1" ]] ; then
    case $COMMAND in
        "spad")
            if [[ $(numeric "$1") ]] ; then
                INDEX="$1"
            else
                err "unknown command \"$1\""
            fi
        ;;
        "ls")
            err "command (ls) does not take an argument"
        ;;
        "grep")
            QUERY="$1"
        ;;
        "stdin")
            err "command (stdin) does not take an argument"
        ;;
        "cat")
            if [[ $(numeric "$1") ]] ; then
                INDEX="$1"
            else
                err "command (cat) index must be numeric"
            fi
        ;;
        "rm")
            while [[ "$1" ]] ; do
                if [[ $(numeric "$1") ]] ; then
                    # fix this syntax
                    # INDICES="$1 $INDICES" (??)
                    INDICES="$INDICES
$1"
                else
                    err "command (rm) index must be numeric"
                fi
                shift
            done
        ;;
        "day")
            err "command (day) does not take an argument"
        ;;
        "yday")
            err "command (yday) does not take an argument"
        ;;
        "nday")
            err "command (nday) does not take an argument"
        ;;
        "note")
            while [[ $# -gt 0 ]] ; do
                NOTE="$NOTE $1"
                shift
            done
        ;;
    esac
fi

# action
case "$COMMAND" in
    "spad")
        if [[ "$INDEX" ]] ; then
            SCRATCHPADS=($(listscratchpads "$BASEDIR"))
            if [[ "$INDEX" -lt "${#SCRATCHPADS[@]}" ]] ; then
                $EDITOR "${SCRATCHPADS[$INDEX]}"
            else
                echo "index outside range"
            fi
        else
            if [[ "$TITLE" ]] ; then
                echo "$TITLE\n" > "$BASEDIR/$TIMESTAMP.$EXT"
            fi
            $EDITOR "$BASEDIR/$TIMESTAMP.$EXT"
        fi
    ;;
    "ls")
        printspads "$(listscratchpads $BASEDIR)"
    ;;
    "grep")
        SCRATCHPADS=$(listscratchpads $BASEDIR)
        CHOSEN=$(grep -li -E "$QUERY" $SCRATCHPADS)
        if [[ "$CHOSEN" ]] ; then
            printspads "$SCRATCHPADS" "$CHOSEN"
        else
            echo "no matches found"
        fi
    ;;
    "stdin")
        cat /dev/stdin > "$BASEDIR/$TIMESTAMP.$EXT"
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
        if [[ "$RESPONSE" != 'y' ]] ; then
            echo "aborted"
            exit 1
        fi
        SCRATCHPADS=($SCRATCHPADS) # how ugly
        for INDEX in $INDICES ; do
            rm "${SCRATCHPADS[$INDEX]}"
        done
    ;;
    "day")
        $EDITOR "$BASEDIR/$(date +%F-%A).txt"
    ;;
    "yday")
        $EDITOR "$BASEDIR/$(date --date yesterday +%F-%A).txt"
    ;;
    "nday")
        $EDITOR "$BASEDIR/$(date --date tomorrow +%F-%A).txt"
    ;;
    "note")
        echo "$(date +%T)>$NOTE" >> "$BASEDIR/$(date +%F-%A).txt"
    ;;
esac


