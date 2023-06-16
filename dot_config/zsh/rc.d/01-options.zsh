#!/usr/bin/env zsh
#
# Options for zsh setopt
#

setopt ALWAYS_TO_END        # move cursor to the end of a completed word.
setopt APPEND_HISTORY       # don't replace the history file
setopt AUTO_CD              # do cd if not command
setopt AUTO_LIST            # automatically list choices on ambiguous completion.
setopt AUTO_MENU            # show completion menu on a successive tab press.
setopt AUTO_NAME_DIRS       # make dir name as parameters
setopt AUTO_PARAM_SLASH     # if completed parameter is a directory, add a trailing slash.
setopt AUTO_PUSHD           # make cd push to stack
unsetopt AUTO_REMOVE_SLASH  # don't remove trailing slash
setopt AUTO_RESUME          # attempt to resume existing job before creating a new process.
#setopt BANG_HIST           # treat the '!' character specially during expansion.
unsetopt BEEP               # i don't want beep
#setopt BRACE_CCL           # allow brace character class list expansion.
unsetopt COMBINING_CHARS    # combine zero-length punctuation characters (accents) with the base character.
setopt COMPLETE_ALIASES     # prevent alias for completion
setopt COMPLETE_IN_WORD     # complete from both ends of a word.
unsetopt CORRECT            # don't try to correct the spelling
setopt EXTENDED_HISTORY     # write the history file in the ':start:elapsed;command' format.
unsetopt FLOW_CONTROL       # disable start/stop characters in shell editor.
setopt GLOB_DOTS            # don't require leading `.' in a filename
setopt HASH_LIST_ALL        # make sure the entire command path hashed
unsetopt HIST_BEEP          # beep when accessing non-existent history.
setopt HIST_EXPIRE_DUPS_FIRST   # expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS    # do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS # delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS     # do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE    # do not record an event starting with a space.
setopt HIST_REDUCE_BLANKS   # shrink history removing blanks
setopt HIST_SAVE_NO_DUPS    # do not write a duplicate event to the history file.
setopt HIST_VERIFY          # do not execute immediately upon history expansion.
setopt INC_APPEND_HISTORY_TIME  # write only after when command finishes (to have proper duration time)
setopt LIST_AMBIGUOUS       # silent cmp
unsetopt LIST_BEEP          # no cmp beep
setopt LIST_PACKED          # make completion list smaller
setopt LIST_TYPES           # show trailing identifying mark
setopt LONG_LIST_JOBS       # list jobs on suspend in the long format by default.
setopt MENU_COMPLETE        # cycle through the candidates
setopt NOTIFY               # report the status of background jobs
setopt NO_BG_NICE           # don't run all background jobs at a lower priority.
unsetopt NO_CHECK_JOBS      # don't report on jobs when shell exit.
unsetopt NO_HUP             # don't kill jobs on shell exit.
setopt NO_INC_APPEND_HISTORY    # write to the history file immediately, not when the shell exits.
setopt NO_MAIL_WARNING      # don't print a warning message if a mail file has been accessed.
setopt NO_PRINT_EXIT_VALUE  # alert if something failed
setopt NO_SH_WORD_SPLIT     # don't split value by words -- only on demand by http://zsh.sourceforge.net/FAQ/zshfaq03.html
setopt NUMERIC_GLOB_SORT    # sort filenames numerically
setopt PATH_DIRS            # perform path search even on command names with slashes.
setopt PRINT_EIGHT_BIT      # display CJK characters just right
#unsetopt PROMPT_CR         # don't print a CR just before zle
unsetopt RC_QUOTES          # allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.
setopt RM_STAR_SILENT       # confirm rm *
setopt SHARE_HISTORY        # disable shared history between terminals / sessions (auto-importing)


{ # New options (may be unavailable)
    setopt PIPE_FAIL        # Exit pipe with rightmost non-zero code
} 2>/dev/null

# notify {{{
REPORTTIME=10               # display process taken longer than 10 second
# }}}

# history {{{
[[ -z $HISTFILE ]] && HISTFILE=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history
[[ ! -x $HISTFILE ]] && mkdir -p ${XDG_DATA_HOME:-$HOME/.local/share}/zsh
HISTSIZE=9999999                 # The maximum number of events to save in the internal history.
SAVEHIST=9999999                 # The maximum number of events to save in the history file.
# }}}

#stty start undef
#stty stop undef
#LISTMAX=20 # in ZLE, the number of matches to list immediately
