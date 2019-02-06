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

### ESLint for React

To use Syntastic with ESLint:

Install eslint, babel-eslint (for ES6 support), and [eslint-plugin-react](https://github.com/yannickcr/eslint-plugin-react):

```
npm install -g eslint
npm install -g babel-eslint
npm install -g eslint-plugin-react
```

Create a config like this in your project's `.eslintrc`, or do so globally by placing it in `~/.eslintrc`:

```
{
    "parser": "babel-eslint",
    "env": {
      "browser": true,
      "node": true
    },
    "settings": {
      "ecmascript": 6,
      "jsx": true
    },
    "plugins": [
      "react"
    ],
    "rules": {
      "strict": 0,
      "quotes": 0,
      "no-unused-vars": 0,
      "camelcase": 0,
      "no-underscore-dangle": 0
    }
}
```

### Prettier - an opinionated code formatter (for React).

* `npm install -g prettier`

### Metals - Languages Server for Scala

Follow instructions in https://scalameta.org/metals/docs/editors/vim.html :

```bash
# Make sure to use coursier v1.1.0-M9 or newer.

curl -L -o coursier https://git.io/coursieri
chmod +x coursier
./coursier bootstrap \
  --java-opt -XX:+UseG1GC \
  --java-opt -XX:+UseStringDeduplication  \
  --java-opt -Xss4m \
  --java-opt -Xms100m \
  --java-opt -Dmetals.client=vim-lsc \
  org.scalameta:metals_2.12:0.4.4 \
  -r bintray:scalacenter/releases \
  -r sonatype:snapshots \
  -o /usr/local/bin/metals-vim -f
```

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
Already installed. No need to do anything.
Instruction here if needed: https://github.com/seebi/tmux-colors-solarized

## Common errors
### YCM with Javascript files

When opening a `.js` or `.jsx` the following error might occur
```
RuntimeError: Warning: Unable to detect a .tern-project file in the hierarchy before /Users/ain/projects/iptools-jquery-modal and no global .tern-config file was found. This is required for accurate JavaScript completion.
```

To solve follow:
https://github.com/ain/.vim/issues/46#issuecomment-381189916
