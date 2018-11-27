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



## Common errors
### YCM with Javascript files

When opening a `.js` or `.jsx` the following error might occur
```
RuntimeError: Warning: Unable to detect a .tern-project file in the hierarchy before /Users/ain/projects/iptools-jquery-modal and no global .tern-config file was found. This is required for accurate JavaScript completion.
```

To solve follow:
https://github.com/ain/.vim/issues/46#issuecomment-381189916
