export FZF_DEFAULT_COMMAND="fd --hidden . $HOME"
# export FZF_DEFAULT_OPTS="--layout=reverse --padding=1 --color=dark"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d --hidden . $HOME"

# file edit with default $EDITOR
function fe() {
  IFS=$'\n' files=($(fd --hidden . $HOME -t f | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# find file in cwd
function ff() {
  IFS=$'\n' files=($(fd --hidden . -t f | fzf -m --prompt 'edit file > ' --reverse --preview 'bat --color=always --style=numbers {}'))
  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# find and extract (.tgz)
function ft() {
	selected=$(find $HOME -type f -name "*.tgz" | fzf);
	if [[ ${selected} != "" ]]; then 
		tar xvzf $selected;
	else
		echo "please select a file to extract"
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
