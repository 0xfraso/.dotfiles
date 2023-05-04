#!/bin/bash

# zsh stuff
if [[ ! -d ~/.oh-my-zsh ]]; then
  echo "Installing Oh My Zsh.."
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  # ohmyzsh will create a sample .zshrc file wich I won't need
  if [[ -e ~/.zshrc ]]; then
    echo "Removing auto generated .zshrc from oh-my-zsh.."
    rm ~/.zshrc
  fi
else
  echo "Oh My Zsh already installed."
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
  echo "Installing zsh-autosuggestions plugin.."
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
  echo "zsh-autosuggestions already installed."
fi

if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
  echo "Installing zsh-syntax-highlighting plugin.."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
  echo "zsh-syntax-highlighting already installed."
fi

# neovim stuff
if [[ ! -d ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]]; then
  git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  echo "Installing packer.nvim.."
else
  echo "packer.nvim already installed."
fi

# tmux plugin manager
if [[ ! -d ~/.local/share/nvim/site/pack/packer/start/packer.nvim ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  echo "Installing tmux plugin manager (tpm).."
else
  echo "tmux plugin manager already installed."
fi

yay -S gum;

if [[ -f ~/.dotfiles/packages.md ]]; then
  PACKAGES=$(cat packages.md | gum choose --no-limit)
fi

yay -S $PACKAGES

STOW_FOLDERS=$(ls -D | gum choose --no-limit)
DOTFILES=$HOME/.dotfiles

for folder in $(echo $STOW_FOLDERS | sed "s/,/ /g")
do 
  echo "stow $folder"
  stow -D $folder
  stow $folder
done

