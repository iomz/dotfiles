#!autoload
#
# install-meslo-nerd-font
#
# taken from p10k wizard:
# https://raw.githubusercontent.com/romkatv/powerlevel10k/master/internal/wizard.zsh

local -r font_base_url='https://github.com/romkatv/powerlevel10k-media/raw/master'
local terminal iterm2_font_size iterm2_old_font=0 can_install_font=0

function ask_font() {
    (( can_install_font )) || return 0
    add_widget 0 print_greeting
    if (( iterm2_old_font )); then
        add_widget 0 flowing -c A new version of '%2FMeslo Nerd Font%f' is available. '%BInstall?%b'
    else
        add_widget 0 flowing -c %BInstall '%b%2FMeslo Nerd Font%f%B?%b'
    fi
    add_widget 0 print
    add_widget 0 print -P "%B(y)  Yes (recommended).%b"
    add_widget 0 print
    add_widget 1
    add_widget 0 print -P "%B(n)  No. Use the current font.%b"
    add_widget 0 print
    add_widget 1
    ask yn
    greeting_printed=1
    case $choice in
        y)
            ask_remove_font || return
            install_font
            ;;
        n) ;;
    esac
    return 0
}


function install_font() {
    [[ $terminal != iTerm2 ]] || return
    command mkdir -p -- ~/Library/Fonts || quit -c
    local style
    for style in Regular Bold Italic 'Bold Italic'; do
        local file="MesloLGS NF ${style}.ttf"
        run_command "Downloading %B$file%b" \
            curl -fsSL -o ~/Library/Fonts/$file.tmp "$font_base_url/${file// /%20}"
        command mv -f -- ~/Library/Fonts/$file{.tmp,} || quit -c
    done
    print -nP -- "Changing %BiTerm2%b settings ..."
    local size=$iterm2_font_size
    [[ $size == 12 ]] && size=13
    local k t v settings=(
        '"Normal Font"'                                 string '"MesloLGS-NF-Regular '$size'"'
        '"Terminal Type"'                               string '"xterm-256color"'
        '"Horizontal Spacing"'                          real   1
        '"Vertical Spacing"'                            real   1
        '"Minimum Contrast"'                            real   0
        '"Use Bold Font"'                               bool   1
        '"Use Bright Bold"'                             bool   1
        '"Use Italic Font"'                             bool   1
        '"ASCII Anti Aliased"'                          bool   1
        '"Non-ASCII Anti Aliased"'                      bool   1
        '"Use Non-ASCII Font"'                          bool   0
        '"Ambiguous Double Width"'                      bool   0
        '"Draw Powerline Glyphs"'                       bool   1
        '"Only The Default BG Color Uses Transparency"' bool   1
    )
    for k t v in $settings; do
        /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:$k $v" \
            ~/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null && continue
        run_command "" /usr/libexec/PlistBuddy -c \
            "Add :\"New Bookmarks\":0:$k $t $v" ~/Library/Preferences/com.googlecode.iterm2.plist
    done
    print -P " %2FOK%f"
    print -nP "Updating %BiTerm2%b settings cache ..."
    run_command "" /usr/bin/defaults read com.googlecode.iterm2
    sleep 3
    print -P " %2FOK%f"
    sleep 1
    clear
    hide_cursor
    print
    flowing +c "%2FMeslo Nerd Font%f" successfully installed.
    print -P ""
    () {
        local out
        out=$(/usr/bin/defaults read 'Apple Global Domain' NSQuitAlwaysKeepsWindows 2>/dev/null) || return
        [[ $out == 1 ]] || return
        out="$(iterm_get OpenNoWindowsAtStartup 2>/dev/null)" || return
        [[ $out == false ]]
    }
    if (( $? )); then
        flowing +c Please "%Brestart iTerm2%b" for the changes to take effect.
        print -P ""
        flowing +c -i 5 "  1. Click" "%BiTerm2 → Quit iTerm2%b" or press "%B⌘ Q%b."
        flowing +c -i 5 "  2. Open %BiTerm2%b."
        print -P ""
        flowing +c "It's" important to "%Brestart iTerm2%b" by following the instructions above.   \
            "It's" "%Bnot enough%b" to close iTerm2 by clicking on the red circle. You must \
            click "%BiTerm2 → Quit iTerm2%b" or press "%B⌘ Q%b."
    else
        flowing +c Please "%Brestart your computer%b" for the changes to take effect.
    fi
    while true; do sleep 60 2>/dev/null; done

    return 0
}


() {
    if [[ "$(uname)" == Darwin && $TERM_PROGRAM == iTerm.app ]]; then
        (( $+commands[curl] )) || return
        [[ $TERM_PROGRAM_VERSION == [2-9]* ]] || return
        if [[ -f ~/Library/Fonts ]]; then
            [[ -d ~/Library/Fonts && -w ~/Library/Fonts ]] || return
        else
            [[ -d ~/Library && -w ~/Library ]] || return
        fi
        [[ -x /usr/libexec/PlistBuddy ]] || return
        [[ -x /usr/bin/plutil ]] || return
        [[ -x /usr/bin/defaults ]] || return
        [[ -f ~/Library/Preferences/com.googlecode.iterm2.plist ]] || return
        [[ -r ~/Library/Preferences/com.googlecode.iterm2.plist ]] || return
        [[ -w ~/Library/Preferences/com.googlecode.iterm2.plist ]] || return
        local guid1 && guid1="$(iterm_get '"Default Bookmark Guid"' 2>/dev/null)" || return
        local guid2 && guid2="$(iterm_get '"New Bookmarks":0:"Guid"' 2>/dev/null)" || return
        local font && font="$(iterm_get '"New Bookmarks":0:"Normal Font"' 2>/dev/null)" || return
        [[ $guid1 == $guid2 ]] || return
        [[ $font != 'MesloLGS-NF-Regular '<-> ]] || return
        [[ $font == (#b)*' '(<->) ]] || return
        [[ $font == 'MesloLGSNer-Regular '<-> ]] && iterm2_old_font=1
        iterm2_font_size=$match[1]
        terminal=iTerm2
        return 0
    fi
    return 1
} && can_install_font=1


ask_font
