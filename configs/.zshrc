# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  dirhistory
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Add timestamp at the right of each command
RPROMPT='[%D{%L:%M:%S}] '$RPROMPT

# Lets files beginning with a . be matched without explicitly specifying the dot.
# Autocomplete will show hidden files
setopt globdots

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [ "$TMUX" = "" ]; then tmux -2; fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Necessary for having psql in path
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export TERM=tmux-256color

function ssht(){
  ssh $* -t 'tmux a || tmux || /bin/bash'
}

# Necessary for https://krew.sigs.k8s.io/
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# change max open files soft limit for this shell. Necessary for uploading some collie resources to s3
ulimit -n 24576

# FZF to respect .gitignore, follow symbolic links, and don't exclude hidden files
# See https://github.com/junegunn/fzf#respecting-gitignore
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Enable Ctrl-x-e to edit command line
autoload -U edit-command-line

# Set NVIM as default editor
alias vim="nvim"
export VISUAL=nvim
export EDITOR="$VISUAL"

# Command to delete branches not on remote.
# Mixture of https://stackoverflow.com/questions/7726949/remove-tracking-branches-no-longer-on-remote and
# https://stackoverflow.com/a/17029936
function git-delete-not-remote(){
   git fetch -p -q; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | grep -v "master" | grep -v "main"  > /tmp/merged-branches &&
     vim /tmp/merged-branches &&
     xargs git branch -D </tmp/merged-branches
}

# Simply necessary for fuzzy git checkout
function fzf-git-branch() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    git branch --color=always --all --sort=-committerdate |
        grep -v HEAD |
        fzf --height 50% --ansi --no-multi --preview-window right:65% \
            --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' |
        sed "s/.* //"
}

# Fuzzy git checkout
# https://polothy.github.io/post/2019-08-19-fzf-git-checkout/
function fzf-git-checkout() {
    git rev-parse HEAD > /dev/null 2>&1 || return

    local branch

    branch=$(fzf-git-branch)
    if [[ "$branch" = "" ]]; then
        echo "No branch selected."
        return
    fi

    # If branch name starts with 'remotes/' then it is a remote branch. By
    # using --track and a remote branch name, it is the same as:
    # git checkout -b branchName --track origin/branchName
    if [[ "$branch" = 'remotes/'* ]]; then
        git checkout --track $branch
    else
        git checkout $branch;
    fi
}
alias gco='fzf-git-checkout'

# Fix for 'gpg failed to sign the data... Inappropriate ioctl for device'
# https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

[ -f ~/.fzf.bash ] && source ~/.private-configs/.paylarc

# Load asdf. This has to be sourced after all changes to $PATH
# . /usr/local/opt/asdf/libexec/asdf.sh # This previouly worked. Not anymore
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# Setting default JDK according to asdf settings.
. ~/.asdf/plugins/java/set-java-home.zsh
