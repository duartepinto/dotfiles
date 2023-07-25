# dotfiles

## To Install

1. Hombrew
   * Restore everything that was installed by restoring my `Brewfile`
1. ~~Tmux~~ _(should be installed through brew's backup)_
1. ~~Zsh~~ _(should be installed through brew's backup)_
1. Oh My Zsh
1. ~~asdf~~ _(should be installed through brew's backup)_
1. ~~Vim~~ _(should be installed through brew's backup)_

## Oh My Zsh

* Install [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh)
* To solve problem with 'agnoster' theme with questions marks appearing in iTerm2, follow [https://github.com/robbyrussell/oh-my-zsh/issues/1906#issuecomment-252443982](https://github.com/robbyrussell/oh-my-zsh/issues/1906#issuecomment-252443982)

## iTerm key mappings

Go to iTerm2 > Preferences > Profiles > Keys

  | Shortcut  | Action               | Code |
  |-----------|----------------------|------|
  | ⌥+←Delete | Send Hex Code        | 0x17 |
  | ⌘+←Delete | Send Hex Code        | 0x15 |
  | ⌥+←       | Send Escape sequence | b    |
  | ⌥+→       | Send Escape sequence | f    |

## Git
Create a global .gitignore.

* `git config --global core.excludesfile ~/.gitignore_global`

Use a template commit message.

* `git config --global commit.template ~/.gitmessage`

Use verbose mode in commit messages.

* `git config --global commit.verbose true`

Use [zdiff3](https://git-scm.com/docs/git-config#Documentation/git-config.txt-mergeconflictStyle) as merge conflict style.

* `git config --global merge.conflictstyle zdiff3`

Always sign the commits with the GPG keys.

* `git config --global commit.gpgsign true`

Automatically create remote branch on push.

* `git config --global push.autoSetupRemote true`

## ASDF

Install plugins that are in `.tool-versions`.

## FZF - A command-line fuzzy finder
_Install should no longer be needed. Will be installed when installing everything with brew's backup. Step 2 still needs to be followed_

Follow instructions in https://github.com/junegunn/fzf#installation

## Setup Vim

### Install vim-plug
```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

## Solarized Theme

I'm using the Solarized Dark theme developed by [Ethan Schoonover](https://ethanschoonover.com/solarized/)

### iTerm

Install and enable `Solarized Dark` theme from [Official repo](https://github.com/altercation/vim-colors-solarized)

Useful links:

* https://gist.github.com/kevin-smets/8568070

### Vim
Already installed. No need to do anything.
Instruction here if needed: https://github.com/altercation/vim-colors-solarized

### Tmux
Instruction here if needed: https://github.com/seebi/tmux-colors-solarized

### Enable italics
https://apple.stackexchange.com/questions/249307/tic-doesnt-read-from-stdin-and-segfaults-when-adding-terminfo-to-support-italic/249385

## Old
### ~~YouCompleteMe~~ _(Plug should handle installation)_

*   `brew install cmake`

### ~~Vim Instant Markdown~~ _(Plug should handle installation)_

Install should no longer be needed since I upgraded to vim-plug_

*   `npm install -g instant-markdown-d`

### ~~xclip~~ _(Will be installed through brew's backup)_

In order to copy the whole tmux buffer into the normal buffer

* `brew install xclip`

## Common errors
### ~~YCM with Javascript files~~
_(Should not happen anymore has I have disabled YCM for every filetype except `.tex`)_

When opening a `.js` or `.jsx` the following error might occur
```
RuntimeError: Warning: Unable to detect a .tern-project file in the hierarchy before /Users/ain/projects/iptools-jquery-modal and no global .tern-config file was found. This is required for accurate JavaScript completion.
```

To solve follow:
https://github.com/ain/.vim/issues/46#issuecomment-381189916

### oh-my-zsh when being loaded by Tmux
This might cause oh-my-zsh to not be properly loaded when zsh is loaded by tmux. Reloading zsh or `source ~/.zshrc` seems to fixed this.

Since I'm relying on brew to install zsh, this might be fixed by following this: https://stackoverflow.com/a/35762726

### `:MetalsInstall` throws an error when using an Apple M1/M2 chip
This might be because of Coursier on M1/M2 chips. There is an issue in [nvim-metals](https://github.com/scalameta/nvim-metals/issues/329) repository regarding that.

Should be fixed by running:
```
softwareupdate --install-rosetta
```
