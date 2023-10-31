# Appended to the default .bashrc via Docker

#### Functions which should be accessible in other bash scripts

# Expose "ssht" command, which attaches to tmux on a given server
ssht () {
    if [[ "${@#--help}" != "$@" || "$@" = "" ]]; then
        echo "Usage: ssht [flags] <server>"
        echo ""
        echo "Connects to <server>, and executes 'tmux attach'."
        return 1
    fi
    ssh -t $* tmux attach
}

# Allow "pdfcompress" command
pdfcompress () {
    if [[ "${@#--help}" != "$@" || "$@" = "" ]]; then
        echo "Usage: pdfcompress <path/to/file.pdf>"
        echo ""
        echo "Will create <path/to/file.compressed.pdf>"
        echo "See also: pdfconcat, pdfextract"
        return 1
    fi
    gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dPDFSETTINGS=/screen -dPrinted=false -dAutoRotatePages=/None -dEmbedAllFonts=true -dSubsetFonts=true -dColorImageDownsampleType=/Bicubic -dColorImageResolution=144 -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=144 -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=144 -sOutputFile="${1::-4}.compressed.pdf" "$1";
}
pdfconcat () {
    if [[ "${@#--help}" != "$@" || "$@" = "" ]]; then
        echo "Usage: pdfconcat <out.pdf> <in1.pdf> [<in2.pdf> ...]"
        echo ""
        echo "Will create <out.pdf> by concatenating PDFs in subsequent arguments."
        echo "See also: pdfcompress, pdfextract"
        return 1
    fi

    OUTPUT="$1"
    shift
    gs -o "$OUTPUT" -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite \
        -dPrinted=false                                \
        -dCompatibilityLevel=1.5                       \
        -dEmbedAllFonts=true                           \
        -dSubsetFonts=true                             \
        -dAntiAliasColorImage=false                    \
        -dAntiAliasGrayImage=false                     \
        -dAntiAliasMonoImage=false                     \
        -dAutoFilterColorImages=false                  \
        -dAutoFilterGrayImages=false                   \
        -dAutoRotatePages=/None                        \
        -dDownsampleColorImages=false                  \
        -dDownsampleGrayImages=false                   \
        -dDownsampleMonoImages=false                   \
        -dColorConversionStrategy=/LeaveColorUnchanged \
        -dConvertCMYKImagesToRGB=false                 \
        -dConvertImagesToIndexed=false                 \
        -dUCRandBGInfo=/Preserve                       \
        -dPreserveHalftoneInfo=true                    \
        -dPreserveOPIComments=true                     \
        -dPreserveOverprintSettings=true               \
        "$@"
}
pdfextract () {
    # Extract pages from a PDF; usage:
    if [[ "${@#--help}" != "$@" || "$@" = "" ]]; then
        echo "Usage: pdfextract <path/to/file.pdf> [-o output.pdf] <first> <last> [<first> <last>...]"
        echo ""
        echo "Will create <path/to/file.extracted.pdf> (or <output.pdf>) using pages between (inclusive) <first> and <last>, optionally from multiple subsets concatenated together."
        echo "See also: pdfcompress, pdfconcat"
        return 1
    fi
    # pdfextract {pdf} {first} {last} [{first} {last}...]
    if [ "$#" -lt "3" ]; then
        echo 'Need at least 3 args'
        return 1
    fi
    PDF="$1"
    shift
    if [ "$1" = "-o" ]; then
        shift
        PDF_OUT="$1"
        shift
    else
        PDF_OUT="${PDF::-4}.extracted.pdf"
    fi
    PDF_MADE="no"
    while [ "$#" -ge "2" ]; do
        if [ "$PDF_MADE" == "no" ]; then
            echo 'Case 1'
            pdfconcat "$PDF_OUT" -dFirstPage="$1" -dLastPage="$2" "$PDF"
            PDF_MADE="yes"
        else
            echo 'Case 2'
            mv "$PDF_OUT" "${PDF_OUT::-4}.1.pdf"
            pdfconcat "${PDF_OUT::-4}.2.pdf" -dFirstPage="$1" -dLastPage="$2" "$PDF"
            pdfconcat "$PDF_OUT" "${PDF_OUT::-4}.1.pdf" "${PDF_OUT::-4}.2.pdf"
            rm "${PDF_OUT::-4}.1.pdf" "${PDF_OUT::-4}.2.pdf"
        fi
        shift
        shift
    done
    if [ "$#" -gt "0" ]; then
        echo 'Bad number of arguments.'
    fi
}

#### If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


# Assume color for ls, tmux
alias gitmeld="git difftool --dir-diff --tool=meld"
alias ls="ls --color=auto -v"  # Color, use natural sorting for numbers
alias tmux='tmux -2'

# Use vim to edit git messages, etc
export EDITOR=vim

# Do not duplicate history entries; if the same command is run multiple times,
# only show it once.
# ignoreboth: Do not save lines starting with a space, do not save duplicates
# erasedups: Active erase prior duplicates of current line
export HISTCONTROL=ignoreboth:erasedups

# Keep per-pane history within tmux
source $(dirname ${BASH_SOURCE})/.bashrc.tmux-history

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
  pwd | awk '{print substr($0, length($0) - 54)}'
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

