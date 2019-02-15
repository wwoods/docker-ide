# Appended to the default .bashrc via Docker

# Assume color for tmux
alias tmux='tmux -2'

# Use vim to edit git messages, etc
export EDITOR=vim

# Fancy prompt with time measuring, etc.
print_elapsed () {
  NOW=`date +%s%N`
  DIFF=$(expr $NOW - $PT_LAST_TIME)
  DIV=1
  SUFFIX="ns"
  DIFFLEN=$(expr length $DIFF)
  if [[ $DIFFLEN -gt 10 ]]; then
    DIV=1000000000
    SUFFIX="s"
  elif [[ $DIFFLEN -gt 7 ]]; then
    DIV=1000000
    SUFFIX="m"
  elif [[ $DIFFLEN -gt 4 ]]; then
    DIV=1000
    SUFFIX="u"
  fi
  # expr prints a warning when result is float, so...
  DIFF=$(echo "$DIFF $DIV" | awk '{ print $1 / $2 - ($1 / $2 % 1); }')
  printf %4d $DIFF
  echo -e $SUFFIX
}
print_path () {
  pwd | awk '{print substr($1, length($1) - 54)}'
  # Update our command number....
  echo `expr \`cat $PT_CMD_FILE 2>/dev/null\` + 1` > $PT_CMD_FILE
}
maybeUpdate () {
  VAL=$1
  if [ "$2" != "$3" ]; then
    VAL=`date +%s%N`
    # echo -e "SET: \n  $2\n  $3" 1>&2
  fi
  printf $VAL
}
export PT_DIR=/run/shm/prompt
if [ ! -d "/run/shm" ]; then
  export PT_DIR=/dev/shm/prompt
fi
mkdir $PT_DIR 2>/dev/null && chmod a+rwx $PT_DIR
export PT_CMD_FILE="$PT_DIR/prompt-cmd-no-$$"
export PT_LAST_TIME=`date +%s%N`
export PT_CMD_LAST=0
export PT_COLOR_NORM=""
export PT_COLOR_FADE=""
export PT_COLOR_GOOD=""
export PT_COLOR_BAD=""

if [ -t 1 ]; then
  # Terminal
  ncolors=$(tput colors)
  if test -n "$ncolors" && test $ncolors -ge 8; then
    # With colors!
    export PT_COLOR_NORM=$(tput sgr0)
    export PT_COLOR_FADE=$(tput setaf 11)
    export PT_COLOR_GOOD=${PT_COLOR_NORM}
    export PT_COLOR_BAD=$(tput setaf 9)
  fi
fi
# Colorized smiley
smiley () {
  if [ $? -eq 0 ]; then
    printf "${PT_COLOR_GOOD}:)${PT_COLOR_NORM}"
  else
    printf "${PT_COLOR_BAD}:(${PT_COLOR_NORM}"
  fi
}
# On exit, delete our command counter.  We need to use a command counter so
# that echo 1 && echo 1 (and piped commands) work towards a single elapsed time,
# not several.
trap 'rm -f $PT_CMD_FILE' EXIT
trap 'PT_LAST_TIME=`maybeUpdate $PT_LAST_TIME $PT_CMD_LAST "\`cat $PT_CMD_FILE 2>/dev/null\`"` PT_CMD_LAST=`cat $PT_CMD_FILE 2>/dev/null`' DEBUG
export PS1="\${PT_COLOR_NORM}\h\$(smiley)\${PT_COLOR_FADE}\$(date +%k:%M)\${PT_COLOR_NORM}\$(print_elapsed) \${PT_COLOR_FADE}\$(print_path)\${PT_COLOR_NORM}\n\$ "

