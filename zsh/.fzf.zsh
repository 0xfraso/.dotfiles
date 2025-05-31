export FZF_DEFAULT_COMMAND="fd --hidden . $HOME"
# export FZF_DEFAULT_OPTS="--layout=reverse --padding=1 --color=dark"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d --hidden . $HOME"

export FZF_DEFAULT_OPTS="--height=100% --layout=reverse --info=inline --border --margin=1 --padding=1 --preview-window 'right:57%' --bind=ctrl-y:preview-up,ctrl-e:preview-down,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down"

BAT_PREVIEW_OPTS="bat --color=always --style=numbers"

# file edit with default $EDITOR
function fe() {
  IFS=$'\n' files=($(fd --hidden . $HOME -t f | fzf -m --prompt 'edit file > ' --reverse --preview "${BAT_PREVIEW_OPTS} {}"))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# find file in cwd
function ff() {
  IFS=$'\n' files=($(fd --hidden . -t f | fzf -m --prompt 'edit file > ' --reverse --preview "${BAT_PREVIEW_OPTS} {}"))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

function fgg() {
  selection=($(rg . --line-number --hidden --no-heading --smart-case -g '!.git' -g '!node_modules' "$@" | fzf -d ':' -n 2.. --no-sort --preview "${BAT_PREVIEW_OPTS} --highlight-line {2} {1}"))
  if [[ -n "$selection" ]]; then
    ${EDITOR:-vim} "${selection%%:*}" +"${${selection%:*}#*:}"
  fi
}

git config --global alias.ll 'log --graph --format="%C(yellow)%h%C(red)%d%C(reset) - %C(bold green)(%ar)%C(reset) %s %C(blue)<%an>%C(reset)"'
function fgl() {
    local selection=$(
      git ll --color=always "$@" | \
        fzf --no-multi --ansi --no-sort \
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
  pid=$((date; ps -ef) |
    fzf --bind='ctrl-r:reload(date; ps -ef)' \
        --header=$'Press CTRL-R to reload\n\n' --header-lines=2 \
        --preview='echo {}' --preview-window=down,3,wrap \
        --layout=reverse --height=80% | awk '{print $2}')
  if [ "x$pid" != "x" ]
  then
    echo $pid | sudo xargs kill -9
  fi
}

function zja() { 
  local selection=($(zellij ls | sed -e 's/\x1B\[[0-9;]*m//g' | fzf | awk '{print $1}'))
  if [[ -n $selection ]]; then
    zellij a ${selection}
  fi
}

function de() { 
  local selection=($(docker container ls | fzf | cut -d ' ' -f1))
  if [[ -n $selection ]]; then
    docker exec -it $selection bash
  fi
}
