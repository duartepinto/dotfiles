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

export PATH="$HOME/.local/bin:$PATH"

# Necessary for having psql in path
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export TERM=xterm-256color

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

# >>> scala-cli completions >>>
fpath=("/Users/duarte/Library/Application Support/ScalaCli/completions/zsh" $fpath)
compinit
# <<< scala-cli completions <<<

# Completion for git-review-commits / grc.
# Supports plain refs, HEAD~N shortcuts, and branch..branch / branch...branch ranges.
function _git_review_commits() {
    local cur="${words[CURRENT]}"

    local branches=( ${(f)"$(git branch --format='%(refname:short)' 2>/dev/null)"} )
    local remote_branches=( ${(f)"$(git branch -r --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||')"} )
    local all_branches=( "${branches[@]}" "${remote_branches[@]}" )

    # Range with ... (symmetric difference) — complete the ref after the operator
    if [[ "$cur" == *"..."* ]]; then
        local prefix="${cur%%...*}..."
        local suffix="${cur##*...}"
        local completions=()
        for b in "${all_branches[@]}"; do
            [[ "$b" == "$suffix"* ]] && completions+=("${prefix}${b}")
        done
        compadd -S '' "${completions[@]}"
        return
    fi

    # Range with .. — complete the ref after the operator
    if [[ "$cur" == *".."* ]]; then
        local prefix="${cur%%\.\.*}.."
        local suffix="${cur##*..}"
        local completions=()
        for b in "${all_branches[@]}"; do
            [[ "$b" == "$suffix"* ]] && completions+=("${prefix}${b}")
        done
        compadd -S '' "${completions[@]}"
        return
    fi

    # Plain ref: HEAD~N shortcuts + branch names
    local -a shortcuts
    shortcuts=(
        'HEAD~:1 commit before HEAD'
        'HEAD~2:2 commits before HEAD'
        'HEAD~3:3 commits before HEAD'
        'HEAD~5:5 commits before HEAD'
        'HEAD~10:10 commits before HEAD'
    )
    _describe -t shortcuts 'shortcuts' shortcuts
    compadd "${all_branches[@]}"
}

compdef _git_review_commits git-review-commits grc

# Review git commits one by one, showing the diff for each.
# Usage: git-review-commits [target]
#   target: a git ref or range (e.g. 'main', 'HEAD~3', 'main...<hash>')
#   When a single ref is given, shows commits from that ref up to HEAD.
function git-review-commits() {
    local start_from=1

    # Parse optional flags to resume a review after a mid-range amend
    while [[ "${1}" == --* ]]; do
        case "$1" in
            --continue)
                # Resume from the position saved by the last non-HEAD amend
                if [[ -z "$_GRC_RESUME_FROM" || -z "$_GRC_RESUME_TARGET" ]]; then
                    echo "Nothing to continue (no paused review found)."
                    return 1
                fi
                start_from="$_GRC_RESUME_FROM"
                set -- "$_GRC_RESUME_TARGET"
                unset _GRC_RESUME_FROM _GRC_RESUME_TARGET
                break
                ;;
            --from=*) start_from="${1#--from=}"; shift ;;
            --from)   start_from="$2"; shift 2 ;;
            *) break ;;
        esac
    done

    # Guard: refuse to start a review while a rebase is already in progress
    local git_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null) || { echo "Not inside a git repository."; return 1; }
    if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
        echo "A rebase is already in progress. Finish or abort it first:"
        echo "  git rebase --continue  (or --abort)"
        if [[ -n "$_GRC_RESUME_FROM" ]]; then
            echo ""
            echo "Once done, resume your review with:  $0 --continue"
        fi
        return 1
    fi

    local target="${1:-HEAD~}"
    local range

    # If the target already contains '..', use it as a range directly
    if [[ "$target" == *".."* ]]; then
        range="$target"
    else
        # Treat as base ref and review everything from there to HEAD
        range="${target}..HEAD"
    fi

    # Collect commits oldest-first so we review in chronological order
    local commits
    commits=(${(f)"$(git log --reverse --format="%H" "$range" 2>/dev/null)"})

    if [[ ${#commits[@]} -eq 0 ]]; then
        echo "No commits found for range: $range"
        return 1
    fi

    local total=${#commits[@]}
    echo "Reviewing $total commit(s) — range: $range"
    echo "Press 'q' inside the diff viewer to advance to the next commit."

    local i=1
    for commit in "${commits[@]}"; do
        # Skip already-reviewed commits when resuming with --from N
        if (( i < start_from )); then
            (( i++ ))
            continue
        fi

        echo ""
        echo "┌─── Commit $i/$total ──────────────────────────────────────────────"
        echo "│ $(git log -1 --format='%C(yellow)%h%Creset  %s' --color=always "$commit")"
        echo "│ $(git log -1 --format='%an • %ad' --date=short "$commit")"
        echo "└───────────────────────────────────────────────────────────────────"

        git show --color=always "$commit" | less -R

        (( i++ ))

        local is_last=$(( i > total ))
        if [[ $is_last -eq 0 ]]; then
            echo -n "\nContinue to commit $i/$total? [Y/n/a=amend] "
        else
            echo -n "\nAmend this commit? [a/n] "
        fi

        read -rk1 response
        echo ""

        case "$response" in
            [aA])
                local short_hash
                short_hash=$(git log -1 --format='%h' "$commit")
                if [[ "$(git rev-parse "$commit")" == "$(git rev-parse HEAD)" ]]; then
                    # Amend HEAD directly — loop will finish naturally afterwards
                    echo "Amending HEAD commit $short_hash..."
                    git commit --amend
                else
                    # Use rebase -i, automatically marking the commit as 'edit'
                    echo "Setting up rebase to amend commit $short_hash..."
                    GIT_SEQUENCE_EDITOR="perl -i -pe 's/^pick/edit/ if \$. == 1'" \
                        git rebase -i "${commit}^"
                    echo ""
                    echo "Git has stopped at $short_hash. Make your changes, then run:"
                    echo "  git add <files> && git commit --amend && git rebase --continue"
                    echo ""
                    export _GRC_RESUME_FROM=$i
                    export _GRC_RESUME_TARGET="$target"
                    echo "Then resume the review with:"
                    echo "  $0 --continue"
                    return 0
                fi
                ;;
            [nNqQ])
                if [[ $is_last -eq 0 ]]; then
                    echo "Review stopped."
                    return 0
                fi
                ;;
        esac
    done

    echo "\n✅ Review complete — $total commit(s) reviewed."
}
alias grc='git-review-commits'

# Kill all sbt processes
function kill-sbt() {
    local pids=$(pgrep -f "sbt")
    if [ -n "$pids" ]; then
echo "Found sbt processes:"
        echo "$pids" | while read pid; do
            local cmd=$(ps -p $pid -o command= 2>/dev/null)
            if [ -n "$cmd" ]; then
                # Find sbt in the command and extract context around it, then truncate to 80 chars
                local sbt_context=$(echo "$cmd" | grep -o '.\{0,20\}sbt.\{0,40\}' | head -c 80)
                echo "  PID $pid: $sbt_context"
            fi
        done
        echo "Killing sbt processes..."
        echo "$pids" | xargs kill -9
        echo "All sbt processes killed."
    else
        echo "No sbt processes found."
    fi
}
