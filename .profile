# It is the default value on OSX, so this line can be omitted
#export LSCOLORS=exfxcxdxbxegedabagacad
LSCOLORS=""
# directory
LSCOLORS=$LSCOLORS"gx"
# symboic link
LSCOLORS=$LSCOLORS"fx"
# socket
LSCOLORS=$LSCOLORS"cx"
# pipe
LSCOLORS=$LSCOLORS"Fx"
# executable
LSCOLORS=$LSCOLORS"ex"
# block special
LSCOLORS=$LSCOLORS"ah"
# character special
LSCOLORS=$LSCOLORS"bh"
# executable with setuid bit set
LSCOLORS=$LSCOLORS"bx"
# executable with setgid bit set
LSCOLORS=$LSCOLORS"bx"
# directory writable to others, with sticky bit
LSCOLORS=$LSCOLORS"cx"
# directory writable to others, without sitcky bit
LSCOLORS=$LSCOLORS"cx"
export LSCOLORS=$LSCOLORS
export LS_COLORS=$LSCOLROS

# Locale setting
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

