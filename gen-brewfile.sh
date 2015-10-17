#!/bin/bash

# Check an existing Brewfile
if [ -e Brewfile ]; then
	echo "Brewfile already exists. Overwriting Brewfile."
    rm -f Brewfile
fi

# brew installed
for i in $(brew list)
do
	echo "install $i"
	echo "install $i" >>Brewfile
done

# brew cask installed
for i in $(brew cask list)
do
    echo "cask install $i"
    echo "cask install $i" >>Brewfile
done
