# KEEP AT THE TOP
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export TERM=xterm-256color
export DOTFILES=$HOME/.dotfiles
export PATH=$HOME/bin:/usr/local/bin:$PATH:$DOTFILES:$HOME/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:
export ROFISCRIPTS=$DOTFILES/rofi-scripts/.config/rofi-scripts
export CONFIG=$HOME/.config
export EDITOR='nvim'
export VISUAL='nvim'

eval "$(starship init zsh)"

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:*' fzf-flags --height=40

# Shell integration
eval "$(fzf --zsh)"

#zsh zsh-autosuggestions
bindkey "^K" up-line-or-history
bindkey "^J" down-line-or-history

my-backward-delete-word() {
    local WORDCHARS=$WORDCHARS
    WORDCHARS="${WORDCHARS//:}"
    WORDCHARS="${WORDCHARS//\/}"
    WORDCHARS="${WORDCHARS//.}"
    zle backward-delete-word # zle <widget-name> will run an existing widget.
}
zle -N my-backward-delete-word # `zle -N` will create a new widget that we can use on the command line
bindkey '^W' my-backward-delete-word

my-backward-delete-whole-word() {
    local WORDCHARS=$WORDCHARS
    [[ ! $WORDCHARS == *":"* ]] && WORDCHARS="$WORDCHARS"":"
    zle backward-delete-word
}
zle -N my-backward-delete-whole-word
bindkey '^[^w' my-backward-delete-whole-word

bindkey '^f' vi-forward-word

bindkey "^[[1;5D" vi-backward-word
bindkey "^[[1;5C" vi-forward-word

autoload -z edit-command-line;
zle -N edit-command-line
bindkey "^X^E" edit-command-line

[[ ! -f ~/.fzf.zsh ]] || source ~/.fzf.zsh
[[ ! -f ~/.wsl.zsh ]] || source ~/.wsl.zsh
[[ ! -f ~/.alias.zsh ]] || source ~/.alias.zsh
[[ ! -f ~/.profile ]] || source ~/.profile

# bun completions
[ -s "/home/fraso/.bun/_bun" ] && source "/home/fraso/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
