#!/usr/bin/env zsh
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic
# General
# setopt brace_ccl          # Allow brace character class list expansion.
# setopt combining_chars    # Combine zero-length punctuation characters (accents) with the base character.
# setopt rc_quotes          # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.
# setopt no_mail_warning    # Don't print a warning message if a mail file has been accessed.
# setopt no_sh_word_split   # Don't split value by words -- only on demand by http://zsh.sourceforge.net/FAQ/zshfaq03.html
### history
# USAGE:
#   * zle keymap 'set-local-history' to toggle exclusive history movement
#   * $ fc -RI $ NICE! manually import history from other terminals (only when you need it)
setopt bang_hist                 # Treat the '!' character specially during expansion.
setopt extended_history          # Write the history file in the ':start:elapsed;command' format.
setopt hist_beep                 # Beep when accessing non-existent history.
setopt hist_expire_dups_first    # Expire a duplicate event first when trimming history.
setopt hist_find_no_dups         # Do not display a previously found event.
setopt hist_ignore_all_dups      # Delete an old recorded event if a new event is a duplicate.
setopt hist_ignore_dups          # Do not record an event that was just recorded again.
setopt hist_ignore_space         # Do not record an event starting with a space.
setopt hist_save_no_dups         # Do not write a duplicate event to the history file.
setopt hist_verify               # Do not execute immediately upon history expansion.
setopt inc_append_history_time   # Write only after when command finishes (to have proper duration time)
setopt no_inc_append_history     # Write to the history file immediately, not when the shell exits.
setopt share_history             # Disable shared history between terminals / sessions (auto-importing)
# DFL: HISTFILE="${ZDOTDIR:-$HOME}/.zhistory"
[[ -z $HISTFILE ]] && HISTFILE=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history
HISTSIZE=9999999
SAVEHIST=9999999
# BET:(audit,transient): prevent frequently changing file to pollute BTRFS snapshots
# HISTFILE=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history
# # INFO: <avg>=20000cmds/year OR: use logrotate-esque way to store old history in archive
# # SRC: https://unix.stackexchange.com/questions/273861/unlimited-history-in-zsh
# HISTSIZE=1000000                 # The maximum number of events to save in the internal history.
# SAVEHIST=1000000                 # The maximum number of events to save in the history file.
# Jobs
# WARN: zsh you have running jobs
# If I exit again, my jobs are killed. But zsh accept some useful option to overide this : nohup nocheckjobs
setopt long_list_jobs     # List jobs on suspend in the long format by default.
setopt auto_resume        # Attempt to resume existing job before creating a new process.
setopt notify             # Report status of background jobs immediately.
setopt no_bg_nice         # Don't run all background jobs at a lower priority.
# setopt no_hup           # Don't kill jobs on shell exit.
setopt no_check_jobs      # Don't report on jobs when shell exit.
setopt no_print_exit_value  # Alert if something failed
{ # New options (may be unavailable)
    setopt pipe_fail        # Exit pipe with rightmost non-zero code
} 2>/dev/null
FPATH="${HOME}"/.config/zsh/completions:${FPATH}

######## -------default
## Disable commands
#disable r
## <C-q> and <C-s> in Vim with iTerm2
#stty start undef
#stty stop undef
## Options
#setopt auto_cd # do cd if not command
#setopt auto_pushd # make cd push to stack
#unsetopt beep # I don't want beep
#setopt print_eight_bit # display CJK characters just right
#setopt rm_star_silent # confirm rm *
#unsetopt prompt_cr # don't print a CR just before zle
#setopt notify # report the status of background jobs
### History
#setopt append_history # don't replace the history file
#setopt extended_history # record timestamp
#setopt hist_find_no_dups # don't display dups
##setopt hist_ignore_all_dups # remove the old history entires
#setopt hist_ignore_dups # don't record contiguous dups
#setopt hist_ignore_space # ignore commands starts with space
#setopt hist_reduce_blanks # shrink history removing blanks
##setopt hist_verify
#setopt share_history # always import commands from the history
#LISTMAX=20 # in ZLE, the number of matches to list immediately
#HISTFILE=$HOME/.zsh_history # file to save history when exits
#HISTSIZE=10000
#SAVEHIST=100000

# display process taken longer than 1 second
REPORTTIME=1