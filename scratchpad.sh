#!/bin/sh

########
# SPAD #
########

HELP="USAGE:
spad [-l] [--md]           - create spad
spad [-l] ls               - list spads
spad [-l] grep             - search spads
spad [-l] _index_          - open spad by index
spad [-l] stdin            - put stdin into spad
spad [-l] cat _index_      - print spad to stdout
spad [-l] rm _index_...    - delete spad by index
spad [-l] day              - open spad for today
spad [-l] yday             - open spad for yesterday
spad [-l] nday             - open spad for tomorrow
spad [-l] note _notes_...  - add a note to spad for today
spad --help                - print this message"

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

listspads() {
    find "$1" -maxdepth 1 -type f \( -name "*.txt" -o -name "*.md" \) \
        -printf '%P\n' | sort -V
}

printspads() { # print by scratchpad title or index
    SCRATCHPADS="$1"
    CHOSEN_SCRATCHPADS="$2" # to choose scratchpads to print by name
    CHOSEN_INDICES="$3"     # to choose scratchpads to print by index

    TERM_SIZE=$(stty size)
    TERM_WIDTH=${TERM_SIZE##* }
    I=0
    if [[ "$CHOSEN_SCRATCHPADS" ]] ; then # print chosen titles
        # I think this matching system could be more idiomatic
        echo "$SCRATCHPADS" | awk -v bp="$BASEPATH" -v tw="$TERM_WIDTH" \
            -v cs="$CHOSEN_SCRATCHPADS" \
        '{
            if (match(cs, $1) > 0) {
                if ((getline head < (bp "/" $1)) < 1) {
                    head = "[EMPTY]"
                }
                print substr(NR-1") "$1": "head, 0, tw)
            }
        }'
    elif [[ "$CHOSEN_INDICES" ]] ; then # print chosen indices
        echo "$SCRATCHPADS" | awk -v bp="$BASEPATH" -v tw="$TERM_WIDTH" \
            -v inds="$CHOSEN_INDICES" \
        '{
            if (match(inds, "b" NR-1 "e") > 0) {
                if ((getline head < (bp "/" $1)) < 1) {
                    head = "[EMPTY]"
                }
                print substr(NR-1") "$1": "head, 0, tw)
            }
        }'
    else # print all
        echo "$SCRATCHPADS" | awk -v bp="$BASEPATH" -v tw="$TERM_WIDTH" \
        '{
            if ((getline head < (bp "/" $1)) < 1) {
                head = "[EMPTY]"
            }
            print substr(NR-1") "$1": "head, 0, tw)
        }'
    fi
}

TIMESTAMP="$(date +%F-%T:%N)"
BASEPATH="$MY_SYNC/corpus/dump/scratchpad"
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
            BASEPATH="."
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
                    INDICES="${INDICES}b${1}e" # b and e; lol
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
            SCRATCHPADS=($(listspads "$BASEPATH"))
            if [[ "$INDEX" -lt "${#SCRATCHPADS[@]}" ]] ; then
                $EDITOR "$BASEPATH/${SCRATCHPADS[$INDEX]}"
            else
                echo "index outside range"
            fi
        else
            if [[ "$TITLE" ]] ; then
                echo "$TITLE\n" > "$BASEPATH/$TIMESTAMP.$EXT"
            fi
            $EDITOR "$BASEPATH/$TIMESTAMP.$EXT"
        fi
    ;;
    "ls")
        printspads "$(listspads $BASEPATH)"
    ;;
    "grep")
        SCRATCHPADS=$(listspads $BASEPATH)
        CHOSEN_SCRATCHPADS=$(grep -li -d skip -E "$QUERY" $BASEPATH/*)
        if [[ "$CHOSEN_SCRATCHPADS" ]] ; then
            printspads "$SCRATCHPADS" "$CHOSEN_SCRATCHPADS"
        else
            echo "no matches found"
        fi
    ;;
    "stdin")
        cat /dev/stdin > "$BASEPATH/$TIMESTAMP.$EXT"
        echo "captured stdin"
    ;;
    "cat")
        SCRATCHPADS=($(listspads "$BASEPATH"))
        cat "${SCRATCHPADS[$INDEX]}"
    ;;
    "rm")
        SCRATCHPADS=$(listspads "$BASEPATH")
        printspads "$SCRATCHPADS" "" "$INDICES"
        echo "confirm rm above scratchpads? y/N"
        read -s -n 1 RESPONSE
        if [[ "$RESPONSE" != 'y' ]] ; then
            echo "aborted"
            exit 1
        fi
        SCRATCHPADS=($SCRATCHPADS) # how ugly
        for INDEX in $INDICES ; do
            rm "$BASEPATH/${SCRATCHPADS[$INDEX]}"
        done
    ;;
    "day")
        $EDITOR "$BASEPATH/$(date +%F-%A).txt"
    ;;
    "yday")
        $EDITOR "$BASEPATH/$(date --date yesterday +%F-%A).txt"
    ;;
    "nday")
        $EDITOR "$BASEPATH/$(date --date tomorrow +%F-%A).txt"
    ;;
    "note")
        echo "$(date +%T)>$NOTE" >> "$BASEPATH/$(date +%F-%A).txt"
    ;;
esac

