#!/bin/sh

########
# SPAD #
########

HELP="
  spad - create and manage timestamped scratchpads

USAGE:
  spad [-l] [--dir] [--md]                create new spad
  spad [-l] [--dir] _index_               open spad by index
  spad [-l] [--dir] _action_ [OPTION...]

ACTION:
  ls               list spads
  grep             search spads
  stdin            put stdin into spad (ex. \$ cat a.txt | spad stdin)
  cat _index_      print spad to stdout
  rm _index_...    delete spads by index
  day              open spad for today
  yday             open spad for yesterday
  nday             open spad for tomorrow
  note _notes_...  add a note to today's spad
  --help           print this message

GLOBAL OPTIONS:
  -l               local (equivalent to --dir .)
  --md             create a titled markdown spad
  --dir _path_     provide path to spad directory

ENVVARS:
  SPAD_DIR         provide path to spad directory (overridden by --dir)"

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
        echo "$SCRATCHPADS" | awk -v bp="$SPAD_DIR" -v tw="$TERM_WIDTH" \
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
        echo "$SCRATCHPADS" | awk -v bp="$SPAD_DIR" -v tw="$TERM_WIDTH" \
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
        echo "$SCRATCHPADS" | awk -v bp="$SPAD_DIR" -v tw="$TERM_WIDTH" \
        '{
            if ((getline head < (bp "/" $1)) < 1) {
                head = "[EMPTY]"
            }
            print substr(NR-1") "$1": "head, 0, tw)
        }'
    fi
}

TIMESTAMP="$(date +%F-%T:%N)"
SPAD_DIR="${SPAD_DIR:-}"
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
            SPAD_DIR="."
        ;;
        "--dir")
            SPAD_DIR="$2"
            shift
        ;;
        "--md")
            EXT="md"
            TITLE="# Spad $TIMESTAMP"
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

if [[ -z "$SPAD_DIR" ]] ; then
    err "no scratchpad directory given (see -l or --dir)"
fi

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
            SCRATCHPADS=($(listspads "$SPAD_DIR"))
            if [[ "$INDEX" -lt "${#SCRATCHPADS[@]}" ]] ; then
                $EDITOR "$SPAD_DIR/${SCRATCHPADS[$INDEX]}"
            else
                echo "index outside range"
            fi
        else
            if [[ "$TITLE" ]] ; then
                echo "$TITLE" > "$SPAD_DIR/$TIMESTAMP.$EXT"
            fi
            $EDITOR "$SPAD_DIR/$TIMESTAMP.$EXT"
        fi
    ;;
    "ls")
        printspads "$(listspads $SPAD_DIR)"
    ;;
    "grep")
        SCRATCHPADS=$(listspads $SPAD_DIR)
        CHOSEN_SCRATCHPADS=$(grep -li -d skip -E "$QUERY" $SPAD_DIR/*)
        if [[ "$CHOSEN_SCRATCHPADS" ]] ; then
            printspads "$SCRATCHPADS" "$CHOSEN_SCRATCHPADS"
        else
            echo "no matches found"
        fi
    ;;
    "stdin")
        cat /dev/stdin > "$SPAD_DIR/$TIMESTAMP.$EXT"
        echo "captured stdin"
    ;;
    "cat")
        SCRATCHPADS=($(listspads "$SPAD_DIR"))
        cat "${SCRATCHPADS[$INDEX]}"
    ;;
    "rm")
        SCRATCHPADS=$(listspads "$SPAD_DIR")
        printspads "$SCRATCHPADS" "" "$INDICES"
        echo "confirm rm above scratchpads? y/N"
        read -s -n 1 RESPONSE
        if [[ "$RESPONSE" != 'y' ]] ; then
            echo "aborted"
            exit 1
        fi
        echo "$SCRATCHPADS" | awk -v bp="$SPAD_DIR" -v inds="$INDICES" \
        '{
            if (match(inds, "b" NR-1 "e") > 0) {
                system("rm " bp "/" $1)
            }
        }'
    ;;
    "day")
        $EDITOR "$SPAD_DIR/$(date +%F-%A).txt"
    ;;
    "yday")
        $EDITOR "$SPAD_DIR/$(date --date yesterday +%F-%A).txt"
    ;;
    "nday")
        $EDITOR "$SPAD_DIR/$(date --date tomorrow +%F-%A).txt"
    ;;
    "note")
        echo "$(date +%T)>$NOTE" >> "$SPAD_DIR/$(date +%F-%A).txt"
    ;;
esac

