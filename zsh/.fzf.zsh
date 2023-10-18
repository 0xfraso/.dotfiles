export FZF_DEFAULT_COMMAND="fd --hidden . $HOME"
# export FZF_DEFAULT_OPTS="--layout=reverse --padding=1 --color=dark"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d --hidden . $HOME"

# file edit with default $EDITOR
function fe() {
  IFS=$'\n' files=($(fd --hidden . $HOME -t f | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --theme=ansi --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# find file in cwd
function ff() {
  IFS=$'\n' files=($(fd --hidden . -t f | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --theme=ansi --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

function fg() {
  IFS=$'\n' files=($(rg -n -H . | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --theme=ansi --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

git config --global alias.ll 'log --graph --format="%C(yellow)%h%C(red)%d%C(reset) - %C(bold green)(%ar)%C(reset) %s %C(blue)<%an>%C(reset)"'
function fgl() {
    local selection=$(
      git ll --color=always "$@" | \
        fzf --no-multi --ansi --no-sort --no-height \
            --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 |
                       xargs -I@ sh -c 'git show --color=always @'"
    )
    if [[ -n $selection ]]; then
        local commit=$(echo "$selection" | sed 's/^[* |]*//' | awk '{print $1}' | tr -d '\n')
        git show $commit
    fi
}

# Install packages using yay (change to pacman/AUR helper of your choice)
function in() {
    yay -Slq | fzf -m -q "$1" -m --preview 'yay -Si {1}'| xargs -ro yay -S
}

# Remove installed packages (change to pacman/AUR helper of your choice)
function re() {
    yay -Qq | fzf -q "$1" -m --preview 'yay -Qi {1}' | xargs -ro yay -Rns
}

# kill process
function fk() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}
