#!/bin/bash

cp .vimrc ~/
mkdir -p ~/.vim/ftplugin/ && cp -R .vim/ftplugin/ "$_"
cp .zshrc ~/
cp .tmux.conf ~/
cp .ideavimrc ~/
cp .gitignore_global ~/
