source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

export FZF_DEFAULT_COMMAND="fd --hidden . $HOME"
export FZF_DEFAULT_OPTS="--layout=reverse --padding=1 --color=dark"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d --hidden . $HOME"

#fzf functions 
# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)

#function fe() {
#  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
#  [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
#}

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

# directory browse with preview
function fb() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" | 
          fzf --prompt 'file browser > ' --multi --reverse --preview ' __cd_nxt="$(echo {})"; __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")"; echo $__cd_path; echo; ls -p --color=always "${__cd_path}"; ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
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
