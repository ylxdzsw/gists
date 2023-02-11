#=== Settings ===#

setopt AUTOCD
setopt AUTOPUSHD PUSHDMINUS PUSHDIGNOREDUPS

disable r

DIRSTACKSIZE=10
HISTFILE=~/.zsh_history
HISTSIZE=65535
SAVEHIST=65535
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Highlight completion selection
zstyle ':completion:*' menu select

# Case and Hyphen insensitive in all completions
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# List all processes, not only children of this session
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

autoload -U compinit && compinit
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search

#=== Prompt ===#

PS2=$'%(?:%F{white}:%F{red})>%f '
PS1=$'%F{green}%n@%m%f %F{magenta}%T%f %F{yellow}%/%f
'$PS2

FIRST_COMMAND_IN_SESSION=true
precmd() {
  print -Pn "\e]0;%n@%m %/\a"
  if [ "$FIRST_COMMAND_IN_SESSION" = true ]; then
    FIRST_COMMAND_IN_SESSION=false
  else
    print ""
  fi
}

#=== environment variables ===#

export PATH="$PATH:/home/ylxdzsw/.deno/bin"
export PATH="$PATH:/home/ylxdzsw/.cargo/bin"
export EDITOR=/usr/bin/vim
export GPG_TTY=$(tty)
export PYTHONDONTWRITEBYTECODE=1
export PYTHONSTARTUP=~/.pythonrc
export RUSTFLAGS="-C target-cpu=native"

# Note: GUI-related variables are defined in the unit file of Sway.service

#=== commands ===#

alias d="dirs -v"
alias 1="cd -"
alias 2="cd -2"
alias 3="cd -3"
alias 4="cd -4"
alias 5="cd -5"
alias 6="cd -6"
alias 7="cd -7"
alias 8="cd -8"
alias 9="cd -9"
alias ls="ls --color"
alias ll="ls --color -alh"
alias pc="pacman"
alias sc="systemctl"
alias jc="journalctl"
alias mc="machinectl"
alias sn="systemd-nspawn"
alias ...="../.."
alias ....="../../.."
alias gcat="gpg --decrypt"
alias sudo="pkexec " # trailing space enable it to run things like "sudo pc -Syu"
alias open="xdg-open"
alias denorun="deno run -A --unstable --no-check"

function cd() {
  builtin cd $@
  ls
}

function dist() {
  export XZ_OPT="-e -T 0"
  tar -cJvf $1.tar.xz $1
  gpg --detach-sign $1.tar.xz
}

function sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
    _zsh_highlight
}

#=== plugins ===#

ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#=== key bindings ===#

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N sudo-command-line

bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word
bindkey "\e\e" sudo-command-line

