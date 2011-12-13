alias sl="ls"
alias svn="env LANG=C svn"
alias svnserve="env LANG=C svnserve"

###############################################
# キーバインド                                #
###############################################
preexec () {
  [ ${STY} ] && echo -ne "\ek${1%% *}\e\\"  # 20070907 修正
}
[ ${STY} ] || screen -rx || screen -D -RR  # 20070905 修正

# viライクキーバインド
#bindkey -v
# Emacsライクキーバインド
bindkey -e

###############################################
# 補完関係                                    #
###############################################
# 標準の補完設定
autoload -U compinit
compinit

# ディレクトリ名を入力するだけでカレントディレクトリを変更
setopt auto_cd

# タブキー連打で補完候補を順に表示
setopt auto_menu

# 自動修正機能(候補を表示)
#setopt correct

# 補完候補を詰めて表示
setopt list_packed

# 補完候補一覧でファイルの種別を識別マーク表示(ls -F の記号)
setopt list_types

# パスの最後に付くスラッシュを自動的に削除しない
setopt noautoremoveslash

# = 以降でも補完できるようにする( --prefix=/usr 等の場合)
setopt magic_equal_subst

# 補完候補リストの日本語を正しく表示
setopt print_eight_bit

# 補完の時に大文字小文字を区別しない(但し、大文字を打った場合は小文字に変換しない)
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# lsコマンドの補完候補にも色付き表示
eval `dircolors`
zstyle ':completion:*:default' list-colors ${LS_COLORS}
# kill の候補にも色付き表示
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

###############################################
# 履歴関係                                    #
###############################################
# ヒストリー機能
HISTFILE=~/.zsh_history      # ヒストリファイルを指定
HISTSIZE=10000               # ヒストリに保存するコマンド数
SAVEHIST=10000               # ヒストリファイルに保存するコマンド数
setopt hist_ignore_all_dups  # 重複するコマンド行は古い方を削除
setopt hist_ignore_dups      # 直前と同じコマンドラインはヒストリに追加しない
setopt share_history         # コマンド履歴ファイルを共有する
setopt append_history        # 履歴を追加 (毎回 .zsh_history を作るのではなく)
setopt inc_append_history    # 履歴をインクリメンタルに追加
setopt hist_no_store         # historyコマンドは履歴に登録しない
setopt hist_reduce_blanks    # 余分な空白は詰めて記録
#setopt hist_ignore_space    # 先頭がスペースの場合、ヒストリに追加しない

# cd - と入力してTabキーで今までに移動したディレクトリを一覧表示
setopt auto_pushd

# ディレクトリスタックに重複する物は古い方を削除
setopt pushd_ignore_dups

# コマンド履歴の検索機能の設定
# ^[  は「エスケープ」
# viなら    Ctrl-v ESC
# Emacsなら Ctrl-q ESC
# viで編集する場合
# 上2行は Ctrl-v を押下した後、希望のキーを押下
# 下2行は「エスケープ」の後にキーの端末コードを入力
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[OA" history-beginning-search-backward-end
bindkey "^[OB" history-beginning-search-forward-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end
# 複数行コマンドの場合、上記の設定だと少々不都合
# tcshの様にする場合は以下のようにする
#bindkey "^P" history-beginning-search-backward-end
#bindkey "^N" history-beginning-search-forward-end

# インクリメンタルサーチの設定
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward

# 全履歴の一覧を出力する
function history-all { history -E 1 }

###############################################
# プロンプト関係                              #
###############################################
# プロンプトに escape sequence (環境変数) を通す
setopt prompt_subst

# ^[  は「エスケープ」
ip=`LANG=C /sbin/ifconfig eth0 | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}'`
PROMPT="%{[31m%B[%n@$ip %/][m%}%#" # 通常のプロンプト
#PROMPT="%{[31m%B[%n@i$p %/][m%}%#" # 通常のプロンプト
#    PROMPT="%{[32+$RANDOM % 5]m%}$LOGNAME@%m%B[%W %T]:%b%{%} %h%% "
#    RPROMPT="[%{m%}%~%{%}]"
PROMPT2="%B%_>%b "                          # forやwhile/複数行入力時などに表示されるプロンプト
SPROMPT="%r is correct? [n,y,a,e]: "        # 入力ミスを確認する場合に表示されるプロンプト
#RPROMPT="%T"                                # 右に表示したいプロンプト(24時間制での現在時刻)

#setopt transient_rprompt                    # 右プロンプトに入力がきたら消す

# ターミナルのタイトル
case "${TERM}" in
kterm*|xterm)
    precmd() {
        echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD}\007"
    }
    ;;
esac

###############################################
# その他                                      #
###############################################
# ファイル作成時のパーミッション
umask 022

setopt no_beep               # ビープ音を消す
#setopt nolistbeep           # 補完候補表示時などにビープ音を鳴らさない

#setopt interactive_comments # コマンドラインで # 以降をコメントとする

setopt numeric_glob_sort     # 辞書順ではなく数値順でソート

setopt no_multios            # zshのリダイレクト機能を制限する

unsetopt promptcr            # 改行コードで終らない出力もちゃんと出力する
#setopt ignore_eof           # Ctrl-dでログアウトしない

setopt no_hup                # ログアウト時にバックグラウンドジョブをkillしない
setopt no_checkjobs          # ログアウト時にバックグラウンドジョブを確認しない
setopt notify                # バックグラウンドジョブが終了したら(プロンプトの表示を待たずに)すぐに知らせる

#setopt rm_star_wait         # rm * を実行する前に確認
setopt rm_star_silent        # rm * を実行する前に確認しない
#setopt no_clobber           # リダイレクトで上書きを禁止
unsetopt no_clobber          # リダイレクトで上書きを許可

#setopt chase_links          # シンボリックリンクはリンク先のパスに変換してから実行
#setopt print_exit_value     # 戻り値が 0 以外の場合終了コードを表示
#setopt single_line_zle      # デフォルトの複数行コマンドライン編集ではなく、１行編集モードになる

# カーソル位置から前方削除(Ctrl-u)
bindkey '^U' backward-kill-line

# Ctrl-h で単語ごとに削除
bindkey "^h" backward-kill-word
# / を単語の一部とみなさない記号の環境変数から削除
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

#function chpwd() { ls }     # cd の後 ls も実行

autoload -U colors
colors

zstyle ':completion:*:default' menu select=1
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ^Dでログアウトしないようにする。
setopt ignore_eof

# ^Iで補完可能な一覧を表示する。(曖昧補完)
setopt auto_list


###############################################
# エイリアス                                  #
###############################################
# 補完される前にオリジナルのコマンドまで展開してチェックする
setopt complete_aliases

# エイリアス
alias ls='ls --color=auto'
alias h='history -E -32'
alias ll='ls -laF --color | more'


# 他の設定ファイルを読み込む
#[ -f $HOME/.zshrc.mine ] && source $HOME/.zshrc.mine
