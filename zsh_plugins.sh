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
