# My Dev setup

## To Install

*   Vim
*   Tmux
*   Zsh
*   Oh My Zsh

## Setup Vim

### Basic vim files

*   `git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime`

### YouCompleteMe

*   `brew install cmake`
*   `cd ~/.vim/bundle/YouCompleteMe`
*   `./install.py --tern-completer`

#### Eclim

*   Install [eclim](http://eclim.org/install.html#installer) for Scala autocomplete
*   If needed run `$ECLIPSE_HOME/eclimd` (if `echo $ECLIPSE` returns empty try in `./Applications/Eclipse.app/Contents/Eclipse/eclimd`)

### Vim Instant Markdown

*   `npm install -g instant-markdown-d`

## Oh My Zsh

* Install [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh)
* To solve problem with 'agnoster' theme with questions marks appearing in iTerm2, follow [https://github.com/robbyrussell/oh-my-zsh/issues/1906#issuecomment-252443982](https://github.com/robbyrussell/oh-my-zsh/issues/1906#issuecomment-252443982)
