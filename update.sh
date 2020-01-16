#!/bin/bash

cp ~/.vimrc .vimrc
mkdir -p .vim/ftplugin/ && cp -R ~/.vim/ftplugin/ "$_"
cp ~/.vim/coc-settings.json .vim/
cp ~/.zshrc .zshrc
cp ~/.tmux.conf .tmux.conf
cp ~/.ideavimrc .ideavimrc
cp ~/.gitignore_global .gitignore_global
