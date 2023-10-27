# spad

A simple scratchpad utility for the command line.

## Quick start

1. Do `export SPAD_DIR="/path/to/dir"` with your desired (empty)
   scratchpad directory.
2. Do `spad` to create and open in `$EDITOR` a timestamped scratchpad
   in `$SPAD_DIR`.
3. Do `spad ls` to list the contents of `$SPAD_DIR`.

## `--help`

```

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
  SPAD_DIR         provide path to spad directory (overridden by --dir)
```


