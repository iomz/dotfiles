#!/usr/bin/env zsh
#
# Named directories
#
# hash -d to create the directory shortcuts for ~<name>
#
hash -d zsh=$ZDOTDIR # cd ~zsh
hash -d nvim=${XDG_CONFIG_HOME:-~/.config}/nvim # cd ~nvim
hash -d chezmoi=${XDG_DATA_HOME:-~/.local/share/}/chezmoi # cd ~chezmoi
