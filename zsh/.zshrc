export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

export BROWSER=/usr/bin/brave
export TERM=xterm-256color

# using bat for manpages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# If you come from bash you might have to change your $PATH.
export DOTFILES=$HOME/.dotfiles
export PATH=$HOME/bin:/usr/local/bin:$PATH:$DOTFILES:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:
export ROFISCRIPTS=$DOTFILES/rofi-scripts/.config/rofi-scripts
export CONFIG=$HOME/.config

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

export EDITOR='nvim'
export VISUAL='nvim'

eval "$(starship init zsh)"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

plugins=(
        git
        zsh-autosuggestions
        zsh-syntax-highlighting
        fzf
    )

source $ZSH/oh-my-zsh.sh

alias nv="nvim"
alias lg="lazygit"
alias dots="cd ~/.dotfiles/"
alias py="python3"
alias tm='tmux'
alias b="bat --color=always --theme=gruvbox-dark"
alias xclip="xclip -selection c"
alias z='zellij'

# ls replacement
TREE_IGNORE="cache|log|logs|node_modules|vendor"
alias ls=' exa --icons --group-directories-first'
alias la=' ls -a'
alias ll=' ls --git -l'
alias lt=' ls --tree -D -L 3 -I ${TREE_IGNORE}'
alias ltt=' ls --tree -D -L 4 -I ${TREE_IGNORE}'
alias lttt=' ls --tree -D -L 5 -I ${TREE_IGNORE}'
alias ltttt=' ls --tree -D -L 6 -I ${TREE_IGNORE}'

#zsh zsh-autosuggestions
bindkey "^f" forward-word

[[ ! -f ~/.fzf.zsh ]] || source ~/.fzf.zsh
[[ ! -f ~/.wsl.zsh ]] || source ~/.wsl.zsh
[[ ! -f ~/.profile ]] || source ~/.profile
